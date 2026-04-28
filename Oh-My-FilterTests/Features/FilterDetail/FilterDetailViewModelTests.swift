import CoreGraphics
import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct FilterDetailViewModelTests {
  @Test("initial load success stores rendered preview")
  func initialLoadSuccessStoresRenderedPreview() async throws {
    let useCase = MockFilterDetailUseCase(result: .success(.sample))
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", useCase: useCase, renderer: renderer)

    await viewModel.send(.task)

    guard case let .loaded(detail, previewState) = viewModel.state.phase else {
      Issue.record("Expected loaded state")
      return
    }

    #expect(detail.id == "filter-123")
    guard case .rendered = previewState else {
      Issue.record("Expected rendered preview")
      return
    }
  }

  @Test("load failure stores message")
  func loadFailureStoresMessage() async {
    let useCase = MockFilterDetailUseCase(result: .failure(FilterDetailServiceError.transport))
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", useCase: useCase, renderer: renderer)

    await viewModel.send(.task)

    guard case let .failed(message, previous) = viewModel.state.phase else {
      Issue.record("Expected failed state")
      return
    }

    #expect(message == "네트워크 상태를 확인한 뒤 다시 시도해 주세요.")
    #expect(previous == nil)
  }

  @Test("render failure uses fallback URLs")
  func renderFailureUsesFallbackURLs() async {
    let useCase = MockFilterDetailUseCase(result: .success(.sample))
    let renderer = MockImageFilterRenderer(result: .failure(ImageFilterRenderingError.renderFailed))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", useCase: useCase, renderer: renderer)

    await viewModel.send(.task)

    guard case let .loaded(_, previewState) = viewModel.state.phase,
          case let .fallback(originalImageURL, filteredImageURL) = previewState else {
      Issue.record("Expected fallback preview")
      return
    }

    #expect(originalImageURL?.absoluteString == "https://example.com/original.jpg")
    #expect(filteredImageURL?.absoluteString == "https://example.com/filtered.jpg")
  }

  @Test("download alert can be dismissed by cancel and confirm")
  func downloadAlertCanBeDismissed() async {
    let useCase = MockFilterDetailUseCase(result: .success(.sample))
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", useCase: useCase, renderer: renderer)

    await viewModel.send(.tapDownload)
    #expect(viewModel.state.alert?.confirmTitle == "확인")

    await viewModel.send(.dismissAlert)
    #expect(viewModel.state.alert == nil)

    await viewModel.send(.tapDownload)
    await viewModel.send(.confirmAlert)
    #expect(viewModel.state.alert == nil)
  }
}

private struct MockFilterDetailUseCase: FilterDetailUseCase {
  let result: Result<FilterDetail, Error>

  func loadFilterDetail(filterID: String) async throws -> FilterDetail {
    try result.get()
  }
}

private struct MockImageFilterRenderer: ImageFilterRendering {
  let result: Result<RenderedFilterImages, Error>

  func render(originalImageURL: URL, filterValues: FilterValues) async throws -> RenderedFilterImages {
    try result.get()
  }
}

private extension FilterDetail {
  static let sample = FilterDetail(
    id: "filter-123",
    title: "청록새록",
    category: "풍경",
    introduction: "맑은 청록빛",
    description: "설명",
    originalImageURL: URL(string: "https://example.com/original.jpg"),
    fallbackFilteredImageURL: URL(string: "https://example.com/filtered.jpg"),
    creator: FilterDetailCreator(
      id: "user-1",
      nick: "SESAC YOON",
      name: "윤새싹",
      profileImageURL: nil,
      introduction: nil,
      hashTags: []
    ),
    metadata: FilterDetailMetadata(
      camera: "iPhone",
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
    price: 0,
    hashTags: [],
    createdAt: nil,
    updatedAt: nil
  )
}

private extension RenderedFilterImages {
  static let sample = RenderedFilterImages(
    original: TestImageFactory.makeCGImage(),
    filtered: TestImageFactory.makeCGImage()
  )
}

enum TestImageFactory {
  static func makeCGImage() -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    let context = CGContext(
      data: nil,
      width: 2,
      height: 2,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    )!
    context.setFillColor(CGColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    return context.makeImage()!
  }
}
