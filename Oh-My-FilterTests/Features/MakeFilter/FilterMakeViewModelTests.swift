import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct FilterMakeViewModelTests {
  @Test("representative image state changes when image data is selected")
  func representativeImageStateChanges() {
    let viewModel = FilterMakeViewModel()
    #expect(viewModel.state.hasRepresentativeImage == false)

    viewModel.send(.representativeImageChanged(Data([0x01, 0x02])))

    #expect(viewModel.state.hasRepresentativeImage == true)
  }

  @Test("selected image info syncs metadata and filter values")
  func selectedImageInfoSyncsMetadataAndFilterValues() {
    let viewModel = FilterMakeViewModel(imageInfoReader: MockFilterMakeImageInfoReader())

    viewModel.send(.representativeImageChanged(Data([0x01, 0x02])))

    #expect(viewModel.state.photoMetadata.camera == "Apple iPhone 16 Pro")
    #expect(viewModel.state.filterParameterValues[.brightness] == 0.35)
    #expect(viewModel.state.draft.photoMetadata.camera == "Apple iPhone 16 Pro")
    #expect(viewModel.state.draft.filterParameterValues[.brightness] == 0.35)
    #expect(viewModel.state.filterValues.brightness == 0.35)
  }

  @Test("category selection updates state")
  func categorySelectionUpdatesState() {
    let viewModel = FilterMakeViewModel()

    viewModel.send(.categorySelected(.night))

    #expect(viewModel.state.category == .night)
  }

  @Test("price input keeps digits and formats with grouping")
  func priceInputNormalizes() {
    let viewModel = FilterMakeViewModel()

    viewModel.send(.priceChanged("abc12,345원"))

    #expect(viewModel.state.priceInput == "12,345")
    #expect(viewModel.state.price == 12_345)
  }

  @Test("draft trims text fields")
  func draftTrimsTextFields() {
    let viewModel = FilterMakeViewModel()

    viewModel.send(.nameChanged("  Soft Mood  "))
    viewModel.send(.introductionChanged("  Warm portrait tone  "))

    #expect(viewModel.state.draft.name == "Soft Mood")
    #expect(viewModel.state.draft.introduction == "Warm portrait tone")
  }

  @Test("filter edit values are kept in make state and draft")
  func filterEditValuesSyncToDraft() {
    let viewModel = FilterMakeViewModel()
    var values = FilterEditParameter.defaultValues
    values[.brightness] = 0.25

    viewModel.send(.filterParameterValuesChanged(values))

    #expect(viewModel.state.filterParameterValues[.brightness] == 0.25)
    #expect(viewModel.state.draft.filterParameterValues[.brightness] == 0.25)
    #expect(viewModel.state.filterValues.brightness == 0.25)
  }
}

private struct MockFilterMakeImageInfoReader: FilterMakeImageInfoReading {
  func selectedImageInfo(from imageData: Data?) -> FilterMakeSelectedImageInfo {
    var values = FilterEditParameter.defaultValues
    values[.brightness] = 0.35

    return FilterMakeSelectedImageInfo(
      imageData: imageData,
      metadata: FilterDetailMetadata(
        camera: "Apple iPhone 16 Pro",
        lens: "Wide 26 mm",
        focalLength: nil,
        aperture: nil,
        shutterSpeed: nil,
        iso: nil
      ),
      filterParameterValues: values
    )
  }
}
