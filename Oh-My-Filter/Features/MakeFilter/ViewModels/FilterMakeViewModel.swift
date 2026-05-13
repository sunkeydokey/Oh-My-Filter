import Foundation
import Observation

@MainActor
@Observable
final class FilterMakeViewModel {
  private(set) var state: FilterMakeState
  private let submitUseCase: any FilterMakeSubmitting
  private let renderer: any ImageFilterRendering
  private let animeConverter: any AnimeGANConverting
  private let filterChangeDebounceDuration: Duration
  private var comparisonRenderTask: Task<Void, Never>?
  private var comparisonRenderRequestID = UUID()
  private var animeConversionTask: Task<Void, Never>?
  private var animeConversionRequestID = UUID()

  init(
    state: FilterMakeState = FilterMakeState(),
    submitUseCase: (any FilterMakeSubmitting)? = nil,
    renderer: any ImageFilterRendering = CoreImageFilterRenderer(),
    animeConverter: any AnimeGANConverting = LiveAnimeGANConverter(),
    filterChangeDebounceDuration: Duration = .milliseconds(300)
  ) {
    self.state = state
    self.submitUseCase = submitUseCase ?? LiveFilterMakeSubmitUseCase()
    self.renderer = renderer
    self.animeConverter = animeConverter
    self.filterChangeDebounceDuration = filterChangeDebounceDuration
    if let imageData = state.representativeImageData {
      scheduleComparisonRender(for: imageData, filterValues: state.filterValues)
    }
  }

  convenience init(
    mode: FilterMakeMode,
    draft: FilterMakeDraft? = nil
  ) {
    self.init(state: FilterMakeState(mode: mode, draft: draft))
  }

  func send(_ action: FilterMakeAction) {
    switch action {
    case let .nameChanged(name):
      state.name = name
    case let .categorySelected(category):
      state.category = category
    case let .introductionChanged(introduction):
      state.introduction = introduction
    case let .priceChanged(input):
      state.priceInput = Self.normalizedPriceInput(input)
    case let .representativeImageChanged(data):
      state.representativeImageData = data
      state.representativePreviewImage = nil
      animeConversionTask?.cancel()
      animeConversionRequestID = UUID()
      state.animeConversionState = .idle
      guard let data else {
        comparisonRenderTask?.cancel()
        comparisonRenderRequestID = UUID()
        state.comparisonPreviewState = nil
        state.photoMetadata = .empty
        state.filterParameterValues = FilterEditParameter.defaultValues
        return
      }
      state.comparisonPreviewState = .rendering
      scheduleComparisonRender(for: data, filterValues: state.filterValues)
    case let .representativeImageInfoChanged(info):
      animeConversionTask?.cancel()
      animeConversionRequestID = UUID()
      state.animeConversionState = .idle
      state.representativeImageData = info.imageData
      state.representativePreviewImage = info.previewImage
      state.photoMetadata = info.metadata
      state.filterParameterValues = info.filterParameterValues
      if let imageData = info.imageData {
        scheduleComparisonRender(for: imageData, filterValues: state.filterValues)
      }
    case let .comparisonPreviewChanged(previewState):
      state.comparisonPreviewState = previewState
    case let .filterParameterValuesChanged(values):
      state.filterParameterValues = values
      guard let imageData = state.representativeImageData else { return }
      state.comparisonPreviewState = .rendering
      scheduleComparisonRender(for: imageData, filterValues: state.filterValues, debounce: filterChangeDebounceDuration)
    case .submitTapped:
      Task {
        await submit()
      }
    case .routeHandled:
      state.route = nil
    case .animeConvertTapped:
      guard state.representativeImageData != nil,
            state.animeConversionState != .converting else { return }
      state.animeConversionState = .converting
      scheduleAnimeConversion()
    case let .animeConversionProduced(result):
      state.animeConversionState = .awaitingChoice(result: result)
    case let .animeConversionFailed(message):
      state.animeConversionState = .failed(message: message)
    case let .animeConversionChoiceMade(useConverted):
      if useConverted,
         case let .awaitingChoice(result) = state.animeConversionState {
        state.representativeImageData = result.convertedData
        state.representativePreviewImage = result.convertedPreview
        state.comparisonPreviewState = .rendering
        scheduleComparisonRender(for: result.convertedData, filterValues: state.filterValues)
      }
      state.animeConversionState = .idle
    case .animeConversionDismissed:
      state.animeConversionState = .idle
    }
  }

  private func submit() async {
    guard state.canSubmit else { return }

    state.isSubmitting = true
    state.submissionMessage = nil
    let draft = state.draft
    let mode = state.mode

    do {
      let detail = try await submitUseCase.submit(draft: draft, mode: mode)
      state.isSubmitting = false
      switch mode {
      case .create:
        state.route = .created(detail)
      case .update:
        state.submissionMessage = successMessage(for: mode)
      }
    } catch is CancellationError {
      state.isSubmitting = false
    } catch {
      state.isSubmitting = false
      state.submissionMessage = Self.message(for: error)
    }
  }

  private func scheduleAnimeConversion() {
    guard let imageData = state.representativeImageData else { return }
    animeConversionTask?.cancel()
    let requestID = UUID()
    animeConversionRequestID = requestID
    animeConversionTask = Task { [animeConverter, imageData, requestID] in
      do {
        let result = try await animeConverter.convert(imageData: imageData, maxPixelSize: 512)
        guard Task.isCancelled == false, self.animeConversionRequestID == requestID else { return }
        self.send(.animeConversionProduced(result))
      } catch is CancellationError {
      } catch {
        guard Task.isCancelled == false, self.animeConversionRequestID == requestID else { return }
        self.send(.animeConversionFailed(Self.animeErrorMessage(for: error)))
      }
    }
  }

  private static func animeErrorMessage(for error: Error) -> String {
    if let e = error as? AnimeGANConversionError {
      switch e {
      case .invalidImageData: return "이미지를 불러올 수 없습니다."
      case .modelLoadFailed: return "모델을 불러올 수 없습니다."
      case .predictionFailed: return "변환에 실패했습니다."
      case .outputDecodingFailed: return "변환 결과를 처리할 수 없습니다."
      }
    }
    return "애니 변환에 실패했습니다. 잠시 후 다시 시도해주세요."
  }

  private func scheduleComparisonRender(for imageData: Data, filterValues: FilterValues, debounce: Duration? = nil) {
    comparisonRenderTask?.cancel()
    let requestID = UUID()
    comparisonRenderRequestID = requestID
    comparisonRenderTask = Task { [renderer, imageData, filterValues, requestID] in
      do {
        if let debounce {
          try await Task.sleep(for: debounce)
          try Task.checkCancellation()
        }
        let images = try await Task.detached(priority: .userInitiated) {
          try await renderer.renderComparisonPreview(originalImageData: imageData, maxPixelSize: 1_024, filterValues: filterValues)
        }.value
        guard Task.isCancelled == false else { return }
        guard self.comparisonRenderRequestID == requestID else { return }
        self.send(.comparisonPreviewChanged(.rendered(images)))
      } catch is CancellationError {
      } catch {
        guard Task.isCancelled == false else { return }
        guard self.comparisonRenderRequestID == requestID else { return }
        self.send(.comparisonPreviewChanged(nil))
      }
    }
  }

  nonisolated static func normalizedPriceInput(_ input: String) -> String {
    let digits = input.filter(\.isNumber)
    guard digits.isEmpty == false else { return "" }
    guard let value = Int(digits) else { return "" }
    return value.formatted(.number)
  }

  private func successMessage(for mode: FilterMakeMode) -> String {
    switch mode {
    case .create:
      "필터를 생성했습니다."
    case .update:
      "필터를 수정했습니다."
    }
  }

  private static func message(for error: Error) -> String {
    if let serviceError = error as? FilterMakeServiceError,
       let message = serviceError.errorDescription {
      return message
    }

    return "필터를 저장할 수 없습니다. 잠시 후 다시 시도해주세요."
  }
}
