import CoreGraphics
import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct FilterMakeViewModelTests {
  @Test("representative image state changes when image data is selected")
  func representativeImageStateChanges() async {
    let viewModel = FilterMakeViewModel()
    #expect(viewModel.state.hasRepresentativeImage == false)

    viewModel.send(.representativeImageChanged(Data([0x01, 0x02])))

    #expect(viewModel.state.hasRepresentativeImage == true)
  }

  @Test("selected image info syncs metadata and filter values")
  func selectedImageInfoSyncsMetadataAndFilterValues() async {
    let viewModel = FilterMakeViewModel()
    var values = FilterEditParameter.defaultValues
    values[.brightness] = 0.35
    let info = FilterMakeSelectedImageInfo(
      imageData: Data([0x01, 0x02]),
      previewImage: TestImageFactory.makeCGImage(),
      metadata: FilterDetailMetadata(camera: "Apple iPhone 16 Pro", lens: "Wide 26 mm", focalLength: nil, aperture: nil, shutterSpeed: nil, iso: nil),
      filterParameterValues: values
    )

    viewModel.send(.representativeImageInfoChanged(info))

    #expect(viewModel.state.photoMetadata.camera == "Apple iPhone 16 Pro")
    #expect(viewModel.state.representativePreviewImage != nil)
    #expect(viewModel.state.filterParameterValues[.brightness] == 0.35)
    #expect(viewModel.state.draft.photoMetadata.camera == "Apple iPhone 16 Pro")
    #expect(viewModel.state.draft.filterParameterValues[.brightness] == 0.35)
    #expect(viewModel.state.filterValues.brightness == 0.35)
  }

  @Test("selected image renders comparison preview")
  func selectedImageRendersComparisonPreview() async {
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterMakeViewModel(renderer: renderer)
    let info = FilterMakeSelectedImageInfo(
      imageData: Data([0x01, 0x02]),
      previewImage: TestImageFactory.makeCGImage(),
      metadata: .empty,
      filterParameterValues: FilterEditParameter.defaultValues
    )

    viewModel.send(.representativeImageInfoChanged(info))
    await waitForImageInfo {
      guard case .rendered? = viewModel.state.comparisonPreviewState else { return false }
      return true
    }

    guard case let .rendered(images)? = viewModel.state.comparisonPreviewState else {
      Issue.record("Expected rendered comparison preview")
      return
    }
    #expect(images == .sample)
  }

  @Test("filter value changes rerender comparison preview")
  func filterValueChangesRerenderComparisonPreview() async {
    let storage = MockImageFilterRendererStorage()
    let renderer = MockImageFilterRenderer(result: .success(.sample), storage: storage)
    let viewModel = FilterMakeViewModel(renderer: renderer)
    let info = FilterMakeSelectedImageInfo(
      imageData: Data([0x01, 0x02]),
      previewImage: TestImageFactory.makeCGImage(),
      metadata: .empty,
      filterParameterValues: FilterEditParameter.defaultValues
    )

    viewModel.send(.representativeImageInfoChanged(info))
    await waitForImageInfo {
      guard case .rendered? = viewModel.state.comparisonPreviewState else { return false }
      return true
    }

    var values = viewModel.state.filterParameterValues
    values[.brightness] = 0.5
    viewModel.send(.filterParameterValuesChanged(values))
    await waitForImageInfo {
      await storage.renderedFilterValues().contains { $0.brightness == 0.5 }
    }

    #expect(await storage.renderedFilterValues().contains { $0.brightness == 0.5 })
    #expect(await storage.calledMethods().allSatisfy { $0 == "renderComparisonPreview" })
  }

  @Test("removing representative image clears comparison preview")
  func removingRepresentativeImageClearsComparisonPreview() async {
    let viewModel = FilterMakeViewModel(renderer: MockImageFilterRenderer(result: .success(.sample)))
    let info = FilterMakeSelectedImageInfo(
      imageData: Data([0x01, 0x02]),
      previewImage: TestImageFactory.makeCGImage(),
      metadata: .empty,
      filterParameterValues: FilterEditParameter.defaultValues
    )

    viewModel.send(.representativeImageInfoChanged(info))
    await waitForImageInfo {
      guard case .rendered? = viewModel.state.comparisonPreviewState else { return false }
      return true
    }

    viewModel.send(.representativeImageChanged(nil))

    #expect(viewModel.state.comparisonPreviewState == nil)
    #expect(viewModel.state.filterParameterValues == FilterEditParameter.defaultValues)
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

  @Test("create submit success emits created route and route handled clears it")
  func createSubmitSuccessEmitsCreatedRoute() async throws {
    let submitUseCase = MockFilterMakeSubmitUseCase(result: .success(.sample))
    let viewModel = FilterMakeViewModel(submitUseCase: submitUseCase)

    viewModel.send(.nameChanged("청록새록"))
    viewModel.send(.introductionChanged("맑은 청록빛"))
    viewModel.send(.priceChanged("2,000"))
    viewModel.send(.representativeImageChanged(Data([0x01])))
    viewModel.send(.submitTapped)

    try await Task.sleep(for: .milliseconds(20))

    guard case let .created(detail)? = viewModel.state.route else {
      Issue.record("Expected created route")
      return
    }
    #expect(detail.id == "filter-123")

    viewModel.send(.routeHandled)
    #expect(viewModel.state.route == nil)
  }

  private func waitForImageInfo(
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

private struct MockFilterMakeSubmitUseCase: FilterMakeSubmitting {
  let result: Result<FilterDetail, Error>

  func submit(draft: FilterMakeDraft, mode: FilterMakeMode) async throws -> FilterDetail {
    try result.get()
  }
}

private struct MockImageFilterRenderer: ImageFilterRendering {
  let result: Result<RenderedFilterImages, Error>
  var storage: MockImageFilterRendererStorage? = nil

  func render(originalImageURL: URL, filterValues: FilterValues) async throws -> RenderedFilterImages {
    if let storage {
      await storage.append(filterValues, method: "render(url:)")
    }
    return try result.get()
  }

  func render(originalImageData: Data, filterValues: FilterValues) async throws -> RenderedFilterImages {
    if let storage {
      await storage.append(filterValues, method: "render(data:)")
    }
    return try result.get()
  }

  func renderPreview(
    originalImageData: Data,
    maxPixelSize: Int,
    filterValues: FilterValues
  ) async throws -> CGImage {
    if let storage {
      await storage.append(filterValues, method: "renderPreview")
    }
    return try result.get().filtered
  }

  func renderComparisonPreview(
    originalImageData: Data,
    maxPixelSize: Int,
    filterValues: FilterValues
  ) async throws -> RenderedFilterImages {
    if let storage {
      await storage.append(filterValues, method: "renderComparisonPreview")
    }
    return try result.get()
  }
}

private actor MockImageFilterRendererStorage {
  private var values: [FilterValues] = []
  private var methods: [String] = []

  func append(_ filterValues: FilterValues, method: String) {
    values.append(filterValues)
    methods.append(method)
  }

  func renderedFilterValues() -> [FilterValues] {
    values
  }

  func calledMethods() -> [String] {
    methods
  }
}

private extension RenderedFilterImages {
  static let sample = RenderedFilterImages(
    original: TestImageFactory.makeCGImage(),
    filtered: TestImageFactory.makeCGImage()
  )
}

private extension FilterDetail {
  static let sample = FilterDetail(
    id: "filter-123",
    title: "청록새록",
    category: "풍경",
    introduction: "맑은 청록빛",
    description: "설명",
    originalImageURL: nil,
    fallbackFilteredImageURL: nil,
    creator: FilterDetailCreator(
      id: "user-1",
      nick: "SESAC YOON",
      name: nil,
      profileImageURL: nil,
      introduction: nil,
      hashTags: []
    ),
    metadata: FilterDetailMetadata(
      camera: nil,
      lens: nil,
      focalLength: nil,
      aperture: nil,
      shutterSpeed: nil,
      iso: nil
    ),
    filterValues: .neutral,
    comments: [],
    isDownloaded: true,
    isLiked: false,
    likeCount: 0,
    buyerCount: 0,
    price: 2_000,
    hashTags: [],
    createdAt: nil,
    updatedAt: nil
  )
}
