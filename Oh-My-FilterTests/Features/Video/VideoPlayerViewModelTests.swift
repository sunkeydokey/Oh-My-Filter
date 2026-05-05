import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct VideoPlayerViewModelTests {
  private static let video = CommunityVideo(
    id: "video-1",
    fileName: "video-1",
    title: "테스트 영상",
    description: "설명",
    duration: 120,
    thumbnailURL: nil,
    availableQualities: ["1080p", "720p"],
    viewCount: 1000,
    likeCount: 42,
    isLiked: false,
    createdAt: "2024-01-15T10:30:00.000Z"
  )

  // MARK: - Load Stream

  @Test("task transitions loading to ready")
  func taskTransitionsToReady() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)

    await viewModel.send(.task)

    if case .ready(let isPlaying) = viewModel.playerPhase {
      #expect(isPlaying == false)
    } else {
      Issue.record("Expected ready phase, got \(viewModel.playerPhase)")
    }
  }

  @Test("task failure transitions to error")
  func taskFailureTransitionsToError() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.failure(VideoPlayerServiceError.notFound))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)

    await viewModel.send(.task)

    if case .error = viewModel.playerPhase {
      // pass
    } else {
      Issue.record("Expected error phase, got \(viewModel.playerPhase)")
    }
  }

  @Test("retry after error reloads stream")
  func retryAfterError() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.failure(VideoPlayerServiceError.serverError))
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)

    await viewModel.send(.task)
    await viewModel.send(.retry)

    if case .ready = viewModel.playerPhase {
      // pass
    } else {
      Issue.record("Expected ready phase after retry, got \(viewModel.playerPhase)")
    }
  }

  // MARK: - Like

  @Test("toggleLike applies optimistic update immediately")
  func toggleLikeOptimisticUpdate() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    await service.enqueueLike(.success(true))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)

    #expect(viewModel.isLiked == false)
    #expect(viewModel.likeCount == 42)

    await viewModel.send(.toggleLike)

    #expect(viewModel.isLiked == true)
    #expect(viewModel.likeCount == 43)
  }

  @Test("toggleLike rolls back on API failure")
  func toggleLikeRollback() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    await service.enqueueLike(.failure(VideoPlayerServiceError.serverError))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)

    await viewModel.send(.toggleLike)

    #expect(viewModel.isLiked == false)
    #expect(viewModel.likeCount == 42)
  }

  // MARK: - Description

  @Test("toggleDescription flips isDescriptionExpanded")
  func toggleDescriptionFlips() async {
    let service = MockVideoPlayerService()
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)

    #expect(viewModel.isDescriptionExpanded == false)
    await viewModel.send(.toggleDescription)
    #expect(viewModel.isDescriptionExpanded == true)
    await viewModel.send(.toggleDescription)
    #expect(viewModel.isDescriptionExpanded == false)
  }

  // MARK: - Quality Menu

  @Test("toggleQualityMenu flips isQualityMenuVisible")
  func toggleQualityMenuFlips() async {
    let service = MockVideoPlayerService()
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)

    #expect(viewModel.isQualityMenuVisible == false)
    await viewModel.send(.toggleQualityMenu)
    #expect(viewModel.isQualityMenuVisible == true)
    await viewModel.send(.toggleQualityMenu)
    #expect(viewModel.isQualityMenuVisible == false)
  }

  @Test("selectQuality updates selectedQuality and closes menu")
  func selectQualityUpdatesAndCloses() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)
    await viewModel.send(.toggleQualityMenu)

    #expect(viewModel.isQualityMenuVisible == true)
    await viewModel.send(.selectQuality("720p"))

    #expect(viewModel.selectedQuality == "720p")
    #expect(viewModel.isQualityMenuVisible == false)
  }
}

// MARK: - Helpers

private extension VideoPlayerViewModelTests {
  static func makeStream() -> VideoStream {
    VideoStream(
      videoId: "video-1",
      streamURL: URL(string: "https://example.com/stream.m3u8"),
      qualities: [
        VideoQuality(label: "1080p", url: URL(string: "https://example.com/1080p.m3u8")),
        VideoQuality(label: "720p", url: URL(string: "https://example.com/720p.m3u8")),
      ],
      subtitles: []
    )
  }
}

// MARK: - Mock Service

private actor MockVideoPlayerService: VideoPlayerServicing {
  private var streamResults: [Result<VideoStream, Error>] = []
  private var likeResults: [Result<Bool, Error>] = []

  func enqueueStream(_ result: Result<VideoStream, Error>) {
    streamResults.append(result)
  }

  func enqueueLike(_ result: Result<Bool, Error>) {
    likeResults.append(result)
  }

  func loadStream(videoId: String) async throws -> VideoStream {
    guard streamResults.isEmpty == false else {
      throw VideoPlayerServiceError.serverError
    }
    return try streamResults.removeFirst().get()
  }

  func toggleLike(videoId: String, status: Bool) async throws -> Bool {
    guard likeResults.isEmpty == false else {
      throw VideoPlayerServiceError.serverError
    }
    return try likeResults.removeFirst().get()
  }
}
