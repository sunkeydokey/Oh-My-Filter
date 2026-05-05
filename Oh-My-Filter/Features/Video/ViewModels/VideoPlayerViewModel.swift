import AVFoundation
import Foundation
import OSLog
import Observation

enum VideoPlayerAction {
  case task
  case retry
  case togglePlay
  case toggleLike
  case toggleDescription
  case toggleQualityMenu
  case selectQuality(String)
  case toggleMute
}

enum VideoPlayerPhase: Equatable {
  case loading
  case ready(isPlaying: Bool)
  case error(message: String)
}

@MainActor
@Observable
final class VideoPlayerViewModel {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "VideoPlayerViewModel"
  )

  var playerPhase: VideoPlayerPhase = .loading
  var isLiked: Bool
  var likeCount: Int
  var selectedQuality: String
  var qualities: [VideoQuality] = []
  var currentTime: Double = 0
  var duration: Double
  var isMuted: Bool = false
  var isDescriptionExpanded: Bool = false
  var isQualityMenuVisible: Bool = false
  private(set) var player: AVPlayer?

  let video: CommunityVideo
  private let service: any VideoPlayerServicing
  private var timeObserver: Any?
  private var statusObservation: NSKeyValueObservation?

  init(video: CommunityVideo, service: any VideoPlayerServicing) {
    self.video = video
    self.service = service
    self.isLiked = video.isLiked
    self.likeCount = video.likeCount
    self.selectedQuality = video.availableQualities.first ?? ""
    self.duration = video.duration
  }

  convenience init(video: CommunityVideo) {
    self.init(video: video, service: LiveVideoPlayerService())
  }

  func send(_ action: VideoPlayerAction) async {
    switch action {
    case .task:
      await loadStream()
    case .retry:
      await loadStream()
    case .togglePlay:
      handleTogglePlay()
    case .toggleLike:
      await handleToggleLike()
    case .toggleDescription:
      isDescriptionExpanded.toggle()
    case .toggleQualityMenu:
      isQualityMenuVisible.toggle()
    case let .selectQuality(label):
      await handleSelectQuality(label)
    case .toggleMute:
      isMuted.toggle()
      player?.isMuted = isMuted
    }
  }

  private func loadStream() async {
    playerPhase = .loading
    currentTime = 0

    do {
      let stream = try await service.loadStream(videoId: video.id)
      qualities = stream.qualities
      if let firstQuality = stream.qualities.first(where: { $0.label == selectedQuality }) ?? stream.qualities.first {
        selectedQuality = firstQuality.label
      }

      let url = qualityURL(for: selectedQuality, in: stream) ?? stream.streamURL
      setupPlayer(url: url)
      playerPhase = .ready(isPlaying: false)
    } catch {
      let message = (error as? VideoPlayerServiceError)?.errorDescription
        ?? VideoPlayerServiceError.serverError.errorDescription
        ?? "잠시 후 다시 시도해 주세요."
      playerPhase = .error(message: message)
      Self.logger.error("❌ [VideoPlayerViewModel] loadStream failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private func handleTogglePlay() {
    guard case let .ready(isPlaying) = playerPhase else { return }
    if isPlaying {
      player?.pause()
      playerPhase = .ready(isPlaying: false)
    } else {
      player?.play()
      playerPhase = .ready(isPlaying: true)
    }
  }

  private func handleToggleLike() async {
    let previousLiked = isLiked
    let previousCount = likeCount

    isLiked = !previousLiked
    likeCount = previousLiked ? previousCount - 1 : previousCount + 1

    do {
      let result = try await service.toggleLike(videoId: video.id, status: isLiked)
      isLiked = result
      likeCount = result ? previousCount + 1 : previousCount - 1
    } catch {
      isLiked = previousLiked
      likeCount = previousCount
      Self.logger.error("❌ [VideoPlayerViewModel] toggleLike failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private func handleSelectQuality(_ label: String) async {
    guard label != selectedQuality else {
      isQualityMenuVisible = false
      return
    }

    let wasPlaying: Bool
    if case .ready(let playing) = playerPhase {
      wasPlaying = playing
    } else {
      wasPlaying = false
    }

    selectedQuality = label
    isQualityMenuVisible = false

    playerPhase = .loading

    do {
      let stream = try await service.loadStream(videoId: video.id)
      let url = qualityURL(for: label, in: stream) ?? stream.streamURL
      setupPlayer(url: url)
      playerPhase = .ready(isPlaying: wasPlaying)
      if wasPlaying { player?.play() }
    } catch {
      let message = (error as? VideoPlayerServiceError)?.errorDescription
        ?? VideoPlayerServiceError.serverError.errorDescription
        ?? "잠시 후 다시 시도해 주세요."
      playerPhase = .error(message: message)
    }
  }

  private func setupPlayer(url: URL?) {
    cleanupPlayer()
    guard let url else { return }

    let newPlayer = AVPlayer(url: url)
    newPlayer.isMuted = isMuted

    timeObserver = newPlayer.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
      queue: .main
    ) { [weak self] time in
      Task { @MainActor [weak self] in
        self?.currentTime = time.seconds
      }
    }

    statusObservation = newPlayer.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
      guard let self else { return }
      Task { @MainActor in
        if case .ready(let isPlaying) = self.playerPhase {
          let nowPlaying = player.timeControlStatus == .playing
          if nowPlaying != isPlaying {
            self.playerPhase = .ready(isPlaying: nowPlaying)
          }
        }
      }
    }

    player = newPlayer
  }

  private func cleanupPlayer() {
    if let observer = timeObserver {
      player?.removeTimeObserver(observer)
      timeObserver = nil
    }
    statusObservation?.invalidate()
    statusObservation = nil
    player?.pause()
    player = nil
  }

  private func qualityURL(for label: String, in stream: VideoStream) -> URL? {
    stream.qualities.first(where: { $0.label == label })?.url
  }

  deinit {
    MainActor.assumeIsolated {
      cleanupPlayer()
    }
  }
}
