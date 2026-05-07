import Foundation
import Observation

@MainActor
@Observable
final class FilterMakeViewModel {
  private(set) var state: FilterMakeState
  private let submitUseCase: any FilterMakeSubmitting
  private let renderer: any ImageFilterRendering
  private var comparisonRenderTask: Task<Void, Never>?
  private var comparisonRenderRequestID = UUID()

  init(
    state: FilterMakeState = FilterMakeState(),
    submitUseCase: (any FilterMakeSubmitting)? = nil,
    renderer: any ImageFilterRendering = CoreImageFilterRenderer()
  ) {
    self.state = state
    self.submitUseCase = submitUseCase ?? LiveFilterMakeSubmitUseCase()
    self.renderer = renderer
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
      scheduleComparisonRender(for: imageData, filterValues: state.filterValues)
    case .submitTapped:
      Task {
        await submit()
      }
    case .routeHandled:
      state.route = nil
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

  private func scheduleComparisonRender(for imageData: Data, filterValues: FilterValues) {
    comparisonRenderTask?.cancel()
    let requestID = UUID()
    comparisonRenderRequestID = requestID
    comparisonRenderTask = Task { [renderer, imageData, filterValues, requestID] in
      do {
        let images = try await Task.detached(priority: .userInitiated) {
          try await renderer.renderComparisonPreview(originalImageData: imageData, maxPixelSize: 1_600, filterValues: filterValues)
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
