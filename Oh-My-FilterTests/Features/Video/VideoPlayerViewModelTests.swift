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

  // MARK: - Lifecycle

  @Test("enterBackground pauses a playing video")
  func enterBackgroundPausesPlayingVideo() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)
    viewModel.playerPhase = .ready(isPlaying: true)

    await viewModel.send(.enterBackground)

    #expect(viewModel.playerPhase == .ready(isPlaying: false))
  }

  @Test("enterBackground while already paused is a no-op")
  func enterBackgroundWhilePausedIsNoOp() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)

    await viewModel.send(.enterBackground)

    #expect(viewModel.playerPhase == .ready(isPlaying: false))
  }

  @Test("enterBackground twice is idempotent")
  func enterBackgroundTwiceIsIdempotent() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)
    viewModel.playerPhase = .ready(isPlaying: true)

    await viewModel.send(.enterBackground)
    await viewModel.send(.enterBackground)

    #expect(viewModel.playerPhase == .ready(isPlaying: false))
  }

  @Test("enterForeground does not auto-resume")
  func enterForegroundDoesNotAutoResume() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)
    viewModel.playerPhase = .ready(isPlaying: true)

    await viewModel.send(.enterBackground)
    await viewModel.send(.enterForeground)

    #expect(viewModel.playerPhase == .ready(isPlaying: false))
  }

  @Test("becomeInactive blocks togglePlay")
  func becomeInactiveBlocksTogglePlay() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)

    await viewModel.send(.becomeInactive)
    await viewModel.send(.togglePlay)

    #expect(viewModel.playerPhase == .ready(isPlaying: false))
  }

  @Test("enterForeground re-enables user input")
  func enterForegroundReEnablesInput() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)

    await viewModel.send(.becomeInactive)
    await viewModel.send(.enterForeground)
    await viewModel.send(.togglePlay)

    #expect(viewModel.playerPhase == .ready(isPlaying: true))
  }

  @Test("enterBackground cancels pending quality change")
  func enterBackgroundCancelsPendingQuality() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)
    await viewModel.send(.selectQuality("720p"))

    await viewModel.send(.enterBackground)

    #expect(viewModel.pendingQualityLabel == nil)
  }

  // MARK: - Subtitles

  @Test("task exposes available subtitles and selects default")
  func taskExposesSubtitles() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream(subtitles: Self.makeSubtitles())))
    await service.enqueueSubtitle(language: "ko", cues: Self.makeKoreanCues())
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)

    await viewModel.send(.task)

    #expect(viewModel.subtitles.map(\.language) == ["en", "ko"])
    #expect(viewModel.selectedSubtitleLanguage == "ko")
    #expect(viewModel.isSubtitlesEnabled == true)
  }

  @Test("task loads default cues and seek shows current text")
  func taskLoadsDefaultCuesAndSeekShowsCurrentText() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream(subtitles: Self.makeSubtitles())))
    await service.enqueueSubtitle(language: "ko", cues: Self.makeKoreanCues())
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)

    await viewModel.send(.seek(to: 1.5))

    #expect(viewModel.isSubtitlesEnabled == true)
    #expect(viewModel.currentSubtitleText == "첫 번째 자막")
  }

  @Test("toggleSubtitles turns enabled subtitles off")
  func toggleSubtitlesTurnsEnabledSubtitlesOff() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream(subtitles: Self.makeSubtitles())))
    await service.enqueueSubtitle(language: "ko", cues: Self.makeKoreanCues())
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)
    await viewModel.send(.seek(to: 1.5))

    await viewModel.send(.toggleSubtitles)

    #expect(viewModel.isSubtitlesEnabled == false)
    #expect(viewModel.currentSubtitleText == nil)
  }

  @Test("seek updates current subtitle text")
  func seekUpdatesCurrentSubtitleText() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream(subtitles: Self.makeSubtitles())))
    await service.enqueueSubtitle(language: "ko", cues: Self.makeKoreanCues())
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)

    await viewModel.send(.seek(to: 4.5))

    #expect(viewModel.currentSubtitleText == "두 번째 자막")
  }

  @Test("selectSubtitle loads selected language cues")
  func selectSubtitleLoadsSelectedLanguage() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream(subtitles: Self.makeSubtitles())))
    await service.enqueueSubtitle(language: "ko", cues: Self.makeKoreanCues())
    await service.enqueueSubtitle(language: "en", cues: [
      VideoSubtitleCue(startTime: 0, endTime: 3, text: "First caption")
    ])
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)
    await viewModel.send(.seek(to: 1))

    await viewModel.send(.selectSubtitle("en"))

    #expect(viewModel.selectedSubtitleLanguage == "en")
    #expect(viewModel.currentSubtitleText == "First caption")
  }

  @Test("toggleSubtitles is ignored when no subtitles are available")
  func toggleSubtitlesWithoutTracksIsIgnored() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)

    await viewModel.send(.toggleSubtitles)

    #expect(viewModel.isSubtitlesEnabled == false)
    #expect(viewModel.currentSubtitleText == nil)
  }

  // MARK: - Full Screen

  @Test("full screen actions only update presentation state")
  func fullScreenActionsUpdatePresentationState() async {
    let service = MockVideoPlayerService()
    await service.enqueueStream(.success(Self.makeStream()))
    let viewModel = VideoPlayerViewModel(video: Self.video, service: service)
    await viewModel.send(.task)

    guard let player = viewModel.player else {
      Issue.record("Expected player to be created")
      return
    }

    #expect(viewModel.isFullScreenPresented == false)
    await viewModel.send(.enterFullScreen)
    #expect(viewModel.isFullScreenPresented == true)
    #expect(viewModel.player.map { $0 === player } == true)

    await viewModel.send(.exitFullScreen)
    #expect(viewModel.isFullScreenPresented == false)
    #expect(viewModel.player.map { $0 === player } == true)
  }
}

// MARK: - Helpers

private extension VideoPlayerViewModelTests {
  static func makeStream(subtitles: [VideoSubtitle] = []) -> VideoStream {
    VideoStream(
      videoId: "video-1",
      streamURL: URL(string: "https://example.com/stream.m3u8"),
      qualities: [
        VideoQuality(label: "1080p", url: URL(string: "https://example.com/1080p.m3u8")),
        VideoQuality(label: "720p", url: URL(string: "https://example.com/720p.m3u8")),
      ],
      subtitles: subtitles
    )
  }

  static func makeSubtitles() -> [VideoSubtitle] {
    [
      VideoSubtitle(
        language: "en",
        name: "English",
        isDefault: false,
        url: URL(string: "https://example.com/subtitles/en.vtt")
      ),
      VideoSubtitle(
        language: "ko",
        name: "한국어",
        isDefault: true,
        url: URL(string: "https://example.com/subtitles/ko.vtt")
      ),
    ]
  }

  static func makeKoreanCues() -> [VideoSubtitleCue] {
    [
      VideoSubtitleCue(startTime: 1, endTime: 3, text: "첫 번째 자막"),
      VideoSubtitleCue(startTime: 4, endTime: 6, text: "두 번째 자막"),
    ]
  }
}

// MARK: - Mock Service

private actor MockVideoPlayerService: VideoPlayerServicing {
  private var streamResults: [Result<VideoStream, Error>] = []
  private var likeResults: [Result<Bool, Error>] = []
  private var subtitleResults: [String: Result<[VideoSubtitleCue], Error>] = [:]

  func enqueueStream(_ result: Result<VideoStream, Error>) {
    streamResults.append(result)
  }

  func enqueueLike(_ result: Result<Bool, Error>) {
    likeResults.append(result)
  }

  func enqueueSubtitle(language: String, cues: [VideoSubtitleCue]) {
    subtitleResults[language] = .success(cues)
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

  func loadSubtitleCues(from url: URL) async throws -> [VideoSubtitleCue] {
    guard let language = url.deletingPathExtension().lastPathComponent.split(separator: "/").last else {
      throw VideoPlayerServiceError.invalidRequest
    }
    guard let result = subtitleResults[String(language)] else {
      throw VideoPlayerServiceError.serverError
    }
    return try result.get()
  }
}
