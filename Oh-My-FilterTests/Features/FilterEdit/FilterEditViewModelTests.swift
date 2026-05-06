import CoreGraphics
import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct FilterEditViewModelTests {
  @Test("slider change updates selected parameter value")
  func sliderChangeUpdatesSelectedParameter() {
    let viewModel = FilterEditViewModel(draft: .sample)
    var values = FilterEditParameter.defaultValues

    values = viewModel.send(.parameterSelected(.brightness), values: values)
    values = viewModel.send(.valueChanged(0.25), values: values)

    #expect(values[.brightness] == 0.25)
    #expect(FilterEditParameter.brightness.displayText(for: values[.brightness, default: 0]) == "25")
  }

  @Test("parameter selection keeps source values unchanged")
  func parameterSelectionKeepsSourceValuesUnchanged() {
    var values = FilterEditParameter.defaultValues
    values[.brightness] = 1.5
    let viewModel = FilterEditViewModel(draft: .sample)

    let updatedValues = viewModel.send(.parameterSelected(.brightness), values: values)

    #expect(updatedValues[.brightness] == 1.5)
    #expect(viewModel.state.selectedParameter == .brightness)
  }

  @Test("external filter values are the editable source")
  func externalFilterValuesAreTheEditableSource() {
    var draftValues = FilterEditParameter.defaultValues
    draftValues[.brightness] = 0.1
    var externalValues = FilterEditParameter.defaultValues
    externalValues[.brightness] = 0.7
    let draft = FilterMakeDraft(
      name: "Sample",
      category: .portrait,
      introduction: "Intro",
      price: 1_000,
      representativeImageData: nil,
      filterParameterValues: draftValues
    )
    let viewModel = FilterEditViewModel(
      draft: draft,
      filterParameterValues: externalValues
    )

    externalValues = viewModel.send(.parameterSelected(.brightness), values: externalValues)
    externalValues = viewModel.send(.valueChanged(0.8), values: externalValues)

    #expect(externalValues[.brightness] == 0.8)
    #expect(draft.filterParameterValues[.brightness] == 0.1)
  }

  @Test("external filter value changes render preview without storing values in state")
  func externalFilterValueChangesRenderPreviewWithoutStoringValuesInState() async {
    let storage = MockEditImageFilterRendererStorage()
    let renderer = MockEditImageFilterRenderer(storage: storage)
    let viewModel = FilterEditViewModel(draft: .sampleWithImage, renderer: renderer)
    var values = FilterEditParameter.defaultValues
    values[.saturation] = 0.6

    viewModel.renderPreview(with: values)
    await waitForRender {
      await storage.lastFilterValues?.saturation == 0.6
    }

    #expect(await storage.lastFilterValues?.saturation == 0.6)
  }

  @Test("slider value is clamped to supported range")
  func sliderValueClamps() {
    let viewModel = FilterEditViewModel(draft: .sample)
    var values = FilterEditParameter.defaultValues

    values = viewModel.send(.parameterSelected(.brightness), values: values)
    values = viewModel.send(.valueChanged(8), values: values)

    #expect(values[.brightness] == 1)
  }

  @Test("undo and redo restore value history")
  func undoRedoRestoresValueHistory() {
    let viewModel = FilterEditViewModel(draft: .sample)
    var values = FilterEditParameter.defaultValues

    values = viewModel.send(.valueChanged(1.2), values: values)
    values = viewModel.send(.undo, values: values)
    #expect(values[.saturation] == 1)

    values = viewModel.send(.redo, values: values)
    #expect(values[.saturation] == 1.2)
  }

  @Test("reset restores parameter defaults from spec")
  func resetRestoresSpecDefaults() {
    let viewModel = FilterEditViewModel(draft: .sample)
    var values = FilterEditParameter.defaultValues

    values = viewModel.send(.parameterSelected(.temperature), values: values)
    values = viewModel.send(.valueChanged(7_000), values: values)
    values = viewModel.send(.reset, values: values)

    #expect(values == FilterEditParameter.defaultValues)
    #expect(values[.temperature] == 5_500)
  }

  @Test("slider change renders filtered representative image")
  func sliderChangeRendersFilteredRepresentativeImage() async {
    let storage = MockEditImageFilterRendererStorage()
    let renderer = MockEditImageFilterRenderer(storage: storage)
    let viewModel = FilterEditViewModel(draft: .sampleWithImage, renderer: renderer)
    var values = FilterEditParameter.defaultValues

    values = viewModel.send(.valueChanged(1.2), values: values)
    await waitForRender {
      let lastFilterValues = await storage.lastFilterValues
      return viewModel.state.previewImage != nil && lastFilterValues?.saturation == 1.2
    }

    #expect(values[.saturation] == 1.2)
    #expect(viewModel.state.previewImage != nil)
    #expect(await storage.dataRenderCount >= 1)
    #expect(await storage.lastFilterValues?.saturation == 1.2)
  }

  @Test("parameter metadata keeps API keys and display text stable")
  func parameterMetadataIsStable() {
    #expect(FilterEditParameter.noiseReduction.apiKey == "noise_reduction")
    #expect(FilterEditParameter.blackPoint.apiKey == "black_point")
    #expect(FilterEditParameter.sharpness.apiKey == "sharpness")
    #expect(FilterEditParameter.contrast.defaultValue == 1)
    #expect(FilterEditParameter.saturation.defaultValue == 1)
    #expect(FilterEditParameter.temperature.defaultValue == 5_500)
    #expect(FilterEditParameter.brightness.displayText(for: 0.25) == "25")
    #expect(FilterEditParameter.contrast.displayText(for: 1.2) == "120%")
    #expect(FilterEditParameter.temperature.displayText(for: 5_500) == "5500K")
    #expect(FilterEditParameter.brightness.descriptionText == "전체 밝기를 부드럽게 조정할 수 있어요")
  }

  private func waitForRender(
    condition: @escaping () async -> Bool
  ) async {
    for _ in 0 ..< 20 {
      if await condition() {
        return
      }
      try? await Task.sleep(for: .milliseconds(10))
    }
  }
}

private struct MockEditImageFilterRenderer: ImageFilterRendering {
  let storage: MockEditImageFilterRendererStorage

  func render(originalImageURL: URL, filterValues: FilterValues) async throws -> RenderedFilterImages {
    await storage.record(filterValues)
    return .sample
  }

  func render(originalImageData: Data, filterValues: FilterValues) async throws -> RenderedFilterImages {
    await storage.record(filterValues)
    return .sample
  }

  func renderPreview(
    originalImageData: Data,
    maxPixelSize: Int,
    filterValues: FilterValues
  ) async throws -> CGImage {
    await storage.record(filterValues)
    return TestImageFactory.makeCGImage()
  }
}

private actor MockEditImageFilterRendererStorage {
  private(set) var dataRenderCount = 0
  private(set) var lastFilterValues: FilterValues?

  func record(_ filterValues: FilterValues) {
    dataRenderCount += 1
    lastFilterValues = filterValues
  }
}

private extension FilterMakeDraft {
  static let sample = FilterMakeDraft(
    name: "Sample",
    category: .portrait,
    introduction: "Intro",
    price: 1_000,
    representativeImageData: nil
  )

  static let sampleWithImage = FilterMakeDraft(
    name: "Sample",
    category: .portrait,
    introduction: "Intro",
    price: 1_000,
    representativeImageData: Data("image".utf8)
  )
}

private extension RenderedFilterImages {
  static let sample = RenderedFilterImages(
    original: TestImageFactory.makeCGImage(),
    filtered: TestImageFactory.makeCGImage()
  )
}
