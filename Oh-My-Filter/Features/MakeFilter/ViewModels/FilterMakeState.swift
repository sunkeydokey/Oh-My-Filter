import CoreGraphics
import Foundation

nonisolated enum AnimeConversionState: Sendable {
  case idle
  case converting
  case awaitingChoice(result: AnimeConversionResult)
  case failed(message: String)
}

extension AnimeConversionState: Equatable {
  static func == (lhs: AnimeConversionState, rhs: AnimeConversionState) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle), (.converting, .converting): return true
    case let (.awaitingChoice(l), .awaitingChoice(r)): return l == r
    case let (.failed(l), .failed(r)): return l == r
    default: return false
    }
  }
}

nonisolated struct FilterMakeState: Equatable, Sendable {
  var mode: FilterMakeMode = .create
  var name = ""
  var category: FilterMakeCategory = .portrait
  var introduction = ""
  var priceInput = "1,000"
  var isSubmitting = false
  var submissionMessage: String?
  var route: FilterMakeRoute?
  var representativeImageData: Data?
  var representativePreviewImage: CGImage?
  var comparisonPreviewState: FilterComparisonPreviewState?
  var animeConversionState: AnimeConversionState = .idle
  var photoMetadata = FilterDetailMetadata(
    camera: nil,
    lens: nil,
    focalLength: nil,
    aperture: nil,
    shutterSpeed: nil,
    iso: nil
  )
  var filterParameterValues = FilterEditParameter.defaultValues

  init(
    mode: FilterMakeMode = .create,
    draft: FilterMakeDraft? = nil
  ) {
    self.mode = mode
    guard let draft else { return }

    name = draft.name
    category = draft.category
    introduction = draft.introduction
    priceInput = draft.priceText
    representativeImageData = draft.representativeImageData
    photoMetadata = draft.photoMetadata
    filterParameterValues = draft.filterParameterValues
  }

  static func == (lhs: FilterMakeState, rhs: FilterMakeState) -> Bool {
    lhs.mode == rhs.mode
      && lhs.name == rhs.name
      && lhs.category == rhs.category
      && lhs.introduction == rhs.introduction
      && lhs.priceInput == rhs.priceInput
      && lhs.isSubmitting == rhs.isSubmitting
      && lhs.submissionMessage == rhs.submissionMessage
      && lhs.route == rhs.route
      && lhs.representativeImageData == rhs.representativeImageData
      && lhs.representativePreviewImage === rhs.representativePreviewImage
      && lhs.comparisonPreviewState == rhs.comparisonPreviewState
      && lhs.animeConversionState == rhs.animeConversionState
      && lhs.photoMetadata == rhs.photoMetadata
      && lhs.filterParameterValues == rhs.filterParameterValues
  }

  var hasRepresentativeImage: Bool {
    representativeImageData != nil
  }

  var price: Int {
    Int(priceInput.filter(\.isNumber)) ?? 0
  }

  var canSubmit: Bool {
    draft.name.isEmpty == false
      && draft.introduction.isEmpty == false
      && draft.price > 0
      && draft.representativeImageData != nil
      && isSubmitting == false
  }

  var submitButtonTitle: String {
    switch mode {
    case .create:
      "필터 생성하기"
    case .update:
      "필터 수정하기"
    }
  }

  var draft: FilterMakeDraft {
    FilterMakeDraft(
      filterID: mode.filterID,
      name: name.trimmingCharacters(in: .whitespacesAndNewlines),
      category: category,
      introduction: introduction.trimmingCharacters(in: .whitespacesAndNewlines),
      price: price,
      representativeImageData: representativeImageData,
      photoMetadata: photoMetadata,
      filterParameterValues: filterParameterValues
    )
  }

  var filterValues: FilterValues {
    FilterEditParameter.filterValues(from: filterParameterValues)
  }
}

nonisolated enum FilterMakeRoute: Equatable, Sendable {
  case created(FilterDetail)
}

nonisolated enum FilterMakeMode: Equatable, Hashable, Sendable {
  case create
  case update(filterID: String)

  var filterID: String? {
    guard case let .update(filterID) = self else { return nil }
    return filterID
  }
}
