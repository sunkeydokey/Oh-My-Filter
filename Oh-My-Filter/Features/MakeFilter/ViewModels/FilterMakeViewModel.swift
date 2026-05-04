import Foundation
import Observation

@MainActor
@Observable
final class FilterMakeViewModel {
  private(set) var state: FilterMakeState
  private let imageInfoReader: any FilterMakeImageInfoReading
  private let submitUseCase: any FilterMakeSubmitting

  init(
    state: FilterMakeState = FilterMakeState(),
    imageInfoReader: any FilterMakeImageInfoReading = LiveFilterMakeImageInfoReader(),
    submitUseCase: (any FilterMakeSubmitting)? = nil
  ) {
    self.state = state
    self.imageInfoReader = imageInfoReader
    self.submitUseCase = submitUseCase ?? LiveFilterMakeSubmitUseCase()
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
      send(.representativeImageInfoChanged(imageInfoReader.selectedImageInfo(from: data)))
    case let .representativeImageInfoChanged(info):
      state.representativeImageData = info.imageData
      state.photoMetadata = info.metadata
      state.filterParameterValues = info.filterParameterValues
    case let .filterParameterValuesChanged(values):
      state.filterParameterValues = values
    case .submitTapped:
      Task {
        await submit()
      }
    }
  }

  private func submit() async {
    guard state.canSubmit else { return }

    state.isSubmitting = true
    state.submissionMessage = nil
    let draft = state.draft
    let mode = state.mode

    do {
      _ = try await submitUseCase.submit(draft: draft, mode: mode)
      state.isSubmitting = false
      state.submissionMessage = successMessage(for: mode)
    } catch is CancellationError {
      state.isSubmitting = false
    } catch {
      state.isSubmitting = false
      state.submissionMessage = Self.message(for: error)
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
