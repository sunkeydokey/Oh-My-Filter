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
  case seek(to: Double)
  case tapPlayerArea
  case enterFullScreen
  case exitFullScreen
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
  var isSeeking: Bool = false
  var isControlsVisible: Bool = true
  var isFullScreenPresented: Bool = false
  private(set) var player: AVPlayer?

  let video: CommunityVideo
  private let service: any VideoPlayerServicing
  private var timeObserver: Any?
  private var statusObservation: NSKeyValueObservation?
  private var itemStatusObservation: NSKeyValueObservation?
  private var controlsHideTask: Task<Void, Never>?

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
    case let .seek(time):
      await handleSeek(to: time)
    case .tapPlayerArea:
      handleTapPlayerArea()
    case .enterFullScreen:
      isFullScreenPresented = true
      isControlsVisible = true
      if case .ready(true) = playerPhase {
        scheduleControlsHide()
      }
    case .exitFullScreen:
      isFullScreenPresented = false
      isControlsVisible = true
      if case .ready(true) = playerPhase {
        scheduleControlsHide()
      }
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
      Self.logger.info("ℹ️ [VideoPlayerViewModel] loadStream url=\(String(describing: url), privacy: .public)")

      setupPlayer(url: url)
      playerPhase = .ready(isPlaying: false)
      isControlsVisible = true
      Self.logger.info("ℹ️ [VideoPlayerViewModel] player ready quality=\(self.selectedQuality, privacy: .public)")
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
      cancelControlsHideTimer()
      isControlsVisible = true
      Self.logger.info("ℹ️ [VideoPlayerViewModel] paused")
    } else {
      player?.play()
      playerPhase = .ready(isPlaying: true)
      scheduleControlsHide()
      Self.logger.info("ℹ️ [VideoPlayerViewModel] play requested itemStatus=\(String(describing: self.player?.currentItem?.status.rawValue), privacy: .public)")
    }
  }

  private func handleTapPlayerArea() {
    guard case .ready(let isPlaying) = playerPhase, isPlaying else { return }
    if isControlsVisible {
      cancelControlsHideTimer()
      isControlsVisible = false
    } else {
      isControlsVisible = true
      scheduleControlsHide()
    }
  }

  private func scheduleControlsHide() {
    cancelControlsHideTimer()
    controlsHideTask = Task { [weak self] in
      try? await Task.sleep(for: .seconds(2))
      guard !Task.isCancelled else { return }
      await MainActor.run { self?.isControlsVisible = false }
    }
  }

  private func cancelControlsHideTimer() {
    controlsHideTask?.cancel()
    controlsHideTask = nil
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

    let resumeTime = player?.currentTime().seconds ?? 0

    selectedQuality = label
    isQualityMenuVisible = false

    do {
      let stream = try await service.loadStream(videoId: video.id)
      guard let url = qualityURL(for: label, in: stream) ?? stream.streamURL else {
        playerPhase = .error(message: VideoPlayerServiceError.invalidResponse.errorDescription ?? "잠시 후 다시 시도해 주세요.")
        return
      }
      Self.logger.info("ℹ️ [VideoPlayerViewModel] quality changed to=\(label, privacy: .public) url=\(url, privacy: .public)")

      swapPlayerItem(url: url, resumeTime: resumeTime, play: wasPlaying)
    } catch {
      let message = (error as? VideoPlayerServiceError)?.errorDescription
        ?? VideoPlayerServiceError.serverError.errorDescription
        ?? "잠시 후 다시 시도해 주세요."
      playerPhase = .error(message: message)
      Self.logger.error("❌ [VideoPlayerViewModel] quality change failed error=\(String(describing: error), privacy: .public)")
    }
  }

  // 새 아이템을 미리 로드한 뒤 교체 — 교체 직전까지 기존 버퍼 화면 유지, 교체 시점에 바로 재생
  private func swapPlayerItem(url: URL, resumeTime: Double, play: Bool) {
    guard let currentPlayer = player else {
      setupPlayer(url: url, resumeTime: resumeTime)
      playerPhase = .ready(isPlaying: play)
      if play { player?.play() }
      return
    }

    Task {
      let asset = AVURLAsset(url: url)
      do {
        // 네트워크에서 메타데이터를 받아 재생 가능 상태가 될 때까지 대기
        _ = try await asset.load(.isPlayable)
      } catch {
        await MainActor.run {
          Self.logger.error("❌ [VideoPlayerViewModel] asset preload failed error=\(String(describing: error), privacy: .public)")
          self.playerPhase = .error(message: "재생 중 오류가 발생했습니다.")
        }
        return
      }

      await MainActor.run {
        let newItem = AVPlayerItem(asset: asset)

        self.itemStatusObservation?.invalidate()
        self.itemStatusObservation = newItem.observe(\.status, options: [.new]) { [weak self] item, _ in
          guard let self else { return }
          Task { @MainActor in
            if case .failed = item.status {
              Self.logger.error("❌ [VideoPlayerViewModel] playerItem failed error=\(String(describing: item.error), privacy: .public)")
              self.playerPhase = .error(message: "재생 중 오류가 발생했습니다.")
            }
          }
        }

        currentPlayer.replaceCurrentItem(with: newItem)

        if resumeTime > 0 {
          let target = CMTime(seconds: resumeTime, preferredTimescale: 600)
          currentPlayer.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        if play { currentPlayer.play() }

        Self.logger.info("ℹ️ [VideoPlayerViewModel] playerItem swapped resumeTime=\(resumeTime, privacy: .public)")
      }
    }
  }

  private func handleSeek(to time: Double) async {
    guard let player else { return }
    currentTime = time
    isSeeking = true
    let target = CMTime(seconds: time, preferredTimescale: 600)
    await player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    isSeeking = false
  }

  private func setupPlayer(url: URL?, resumeTime: Double = 0) {
    cleanupPlayer()
    guard let url else {
      Self.logger.error("❌ [VideoPlayerViewModel] setupPlayer called with nil url")
      return
    }

    let asset = AVURLAsset(url: url)
    let playerItem = AVPlayerItem(asset: asset)
    let newPlayer = AVPlayer(playerItem: playerItem)
    newPlayer.isMuted = isMuted

    timeObserver = newPlayer.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
      queue: .main
    ) { [weak self] time in
      Task { @MainActor [weak self] in
        guard let self, !self.isSeeking else { return }
        self.currentTime = time.seconds
      }
    }

    statusObservation = newPlayer.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
      guard let self else { return }
      Task { @MainActor in
        let status = player.timeControlStatus
        Self.logger.debug("🔍 [VideoPlayerViewModel] timeControlStatus=\(status.rawValue, privacy: .public)")
        if case .ready(let isPlaying) = self.playerPhase {
          let nowPlaying = status == .playing || status == .waitingToPlayAtSpecifiedRate
          if nowPlaying != isPlaying {
            self.playerPhase = .ready(isPlaying: nowPlaying)
          }
        }
      }
    }

    itemStatusObservation = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
      guard let self else { return }
      Task { @MainActor in
        switch item.status {
        case .readyToPlay:
          Self.logger.info("ℹ️ [VideoPlayerViewModel] playerItem readyToPlay")
        case .failed:
          let err = item.error
          Self.logger.error("❌ [VideoPlayerViewModel] playerItem failed error=\(String(describing: err), privacy: .public)")
          self.playerPhase = .error(message: "재생 중 오류가 발생했습니다.")
        case .unknown:
          Self.logger.debug("🔍 [VideoPlayerViewModel] playerItem status unknown (loading)")
        @unknown default:
          break
        }
      }
    }

    player = newPlayer

    if resumeTime > 0 {
      let target = CMTime(seconds: resumeTime, preferredTimescale: 600)
      newPlayer.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    }
  }

  private func cleanupPlayer() {
    if let observer = timeObserver {
      player?.removeTimeObserver(observer)
      timeObserver = nil
    }
    statusObservation?.invalidate()
    statusObservation = nil
    itemStatusObservation?.invalidate()
    itemStatusObservation = nil
    player?.pause()
    player = nil
  }

  private func qualityURL(for label: String, in stream: VideoStream) -> URL? {
    stream.qualities.first(where: { $0.label == label })?.url
  }

  deinit {
    MainActor.assumeIsolated {
      controlsHideTask?.cancel()
      cleanupPlayer()
    }
  }
}
