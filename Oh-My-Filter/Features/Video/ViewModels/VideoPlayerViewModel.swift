import AVFoundation
import Foundation
import OSLog
import Observation

private enum HLSPolicy {
  /// 서버 HLS 세그먼트 길이(초) — 서버 설정에 맞게 조정
  static let segmentDuration: Double = 2.0
  /// 버퍼 잔여량이 이 미만이면 즉시 전환 (지연 전환 없음)
  static let deferThreshold: Double = segmentDuration
  /// 경계 옵저버를 버퍼 끝보다 이만큼 앞에서 발화
  static let boundaryLeadTime: Double = 0.1
  /// 지연 전환 중 기존 아이템의 추가 버퍼링 허용량(초)
  static let frozenBufferDuration: Double = segmentDuration
}

enum VideoPlayerAction {
  case task
  case retry
  case togglePlay
  case toggleLike
  case toggleDescription
  case toggleQualityMenu
  case selectQuality(String)
  case toggleMute
  case toggleSubtitles
  case toggleSubtitleMenu
  case selectSubtitle(String)
  case seek(to: Double)
  case tapPlayerArea
  case enterFullScreen
  case exitFullScreen
  case enterBackground
  case enterForeground
  case becomeInactive
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
  var subtitles: [VideoSubtitle] = []
  var selectedSubtitleLanguage: String?
  var isSubtitlesEnabled: Bool = false
  var isSubtitleMenuVisible: Bool = false
  var isSubtitleLoading: Bool = false
  var currentSubtitleText: String?
  var isDescriptionExpanded: Bool = false
  var isQualityMenuVisible: Bool = false
  var isSeeking: Bool = false
  var isControlsVisible: Bool = true
  var isFullScreenPresented: Bool = false
  private(set) var player: AVPlayer?
  private var isInactive = false

  let video: CommunityVideo
  private let service: any VideoPlayerServicing
  private var timeObserver: Any?
  private var statusObservation: NSKeyValueObservation?
  private var itemStatusObservation: NSKeyValueObservation?
  private var controlsHideTask: Task<Void, Never>?
  private var pendingQuality: PendingQualityChange?
  private(set) var pendingQualityLabel: String?
  private var subtitleCueCache: [String: [VideoSubtitleCue]] = [:]
  private let likeCommitter: DebouncedBooleanCommitter
  private var pendingLikeRollback: (isLiked: Bool, likeCount: Int)?

  private struct PendingQualityChange {
    let label: String
    let url: URL
    let bufferedEnd: Double
    var loadedAsset: AVURLAsset?
    var preloadTask: Task<Void, Never>?
    var boundaryToken: Any?
  }

  init(
    video: CommunityVideo,
    service: any VideoPlayerServicing,
    likeDebounceDuration: Duration = .milliseconds(300)
  ) {
    self.video = video
    self.service = service
    self.isLiked = video.isLiked
    self.likeCount = video.likeCount
    self.selectedQuality = video.availableQualities.first ?? ""
    self.duration = video.duration
    self.likeCommitter = DebouncedBooleanCommitter(duration: likeDebounceDuration)
  }

  convenience init(video: CommunityVideo) {
    self.init(video: video, service: LiveVideoPlayerService())
  }

  func send(_ action: VideoPlayerAction) async {
    if isInactive {
      switch action {
      case .enterBackground, .enterForeground, .becomeInactive: break
      default: return
      }
    }

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
    case .toggleSubtitles:
      await handleToggleSubtitles()
    case .toggleSubtitleMenu:
      guard subtitles.count > 1 else { return }
      isSubtitleMenuVisible.toggle()
    case let .selectSubtitle(language):
      await handleSelectSubtitle(language)
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
    case .enterBackground:
      if case .ready(true) = playerPhase {
        player?.pause()
        playerPhase = .ready(isPlaying: false)
      }
      cancelPendingQualityChange()
      cancelControlsHideTimer()
      isControlsVisible = true
      isInactive = true
    case .enterForeground:
      isInactive = false
    case .becomeInactive:
      isInactive = true
    }
  }

  private func loadStream() async {
    likeCommitter.cancel()
    pendingLikeRollback = nil
    playerPhase = .loading
    currentTime = 0

    do {
      let stream = try await service.loadStream(videoId: video.id)
      qualities = stream.qualities
      configureSubtitles(stream.subtitles)
      if let firstQuality = stream.qualities.first(where: { $0.label == selectedQuality }) ?? stream.qualities.first {
        selectedQuality = firstQuality.label
      }

      let url = qualityURL(for: selectedQuality, in: stream) ?? stream.streamURL
      Self.logger.info("ℹ️ [VideoPlayerViewModel] loadStream url=\(String(describing: url), privacy: .public)")

      try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
      try? AVAudioSession.sharedInstance().setActive(true)
      setupPlayer(url: url)
      playerPhase = .ready(isPlaying: false)
      isControlsVisible = true
      Self.logger.info("ℹ️ [VideoPlayerViewModel] player ready quality=\(self.selectedQuality, privacy: .public)")
      await enableDefaultSubtitlesIfAvailable()
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
    if pendingLikeRollback == nil {
      pendingLikeRollback = (isLiked, likeCount)
    }

    let targetStatus = isLiked == false
    isLiked = targetStatus
    likeCount = max(0, likeCount + (targetStatus ? 1 : -1))

    let videoID = video.id
    likeCommitter.schedule(
      status: targetStatus,
      operation: { [service] status in
        try await service.toggleLike(videoId: videoID, status: status)
      },
      completion: { [weak self] result, requestedStatus in
        guard let self else { return }
        switch result {
        case let .success(confirmedStatus) where confirmedStatus == requestedStatus:
          pendingLikeRollback = nil
        default:
          rollbackLike()
          if case let .failure(error) = result {
            Self.logger.error("❌ [VideoPlayerViewModel] toggleLike failed error=\(String(describing: error), privacy: .public)")
          }
        }
      }
    )
  }

  private func rollbackLike() {
    guard let pendingLikeRollback else { return }
    isLiked = pendingLikeRollback.isLiked
    likeCount = pendingLikeRollback.likeCount
    self.pendingLikeRollback = nil
  }

  private func handleToggleSubtitles() async {
    guard subtitles.isEmpty == false else { return }

    if isSubtitlesEnabled {
      isSubtitlesEnabled = false
      currentSubtitleText = nil
      return
    }

    if selectedSubtitleLanguage == nil {
      selectedSubtitleLanguage = defaultSubtitle()?.language
    }

    guard let selectedSubtitleLanguage else { return }

    do {
      try await loadSubtitleIfNeeded(language: selectedSubtitleLanguage)
      isSubtitlesEnabled = true
      updateCurrentSubtitle(for: currentTime)
    } catch {
      isSubtitlesEnabled = false
      currentSubtitleText = nil
      Self.logger.error("❌ [VideoPlayerViewModel] subtitle load failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private func enableDefaultSubtitlesIfAvailable() async {
    guard
      subtitles.isEmpty == false,
      isSubtitlesEnabled == false
    else { return }

    if selectedSubtitleLanguage == nil {
      selectedSubtitleLanguage = defaultSubtitle()?.language
    }

    guard let selectedSubtitleLanguage else { return }

    do {
      try await loadSubtitleIfNeeded(language: selectedSubtitleLanguage)
      isSubtitlesEnabled = true
      updateCurrentSubtitle(for: currentTime)
    } catch {
      isSubtitlesEnabled = false
      currentSubtitleText = nil
      Self.logger.error("❌ [VideoPlayerViewModel] default subtitle load failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private func handleSelectSubtitle(_ language: String) async {
    guard subtitles.contains(where: { $0.language == language }) else { return }

    selectedSubtitleLanguage = language
    isSubtitleMenuVisible = false

    guard isSubtitlesEnabled else {
      currentSubtitleText = nil
      return
    }

    do {
      try await loadSubtitleIfNeeded(language: language)
      updateCurrentSubtitle(for: currentTime)
    } catch {
      isSubtitlesEnabled = false
      currentSubtitleText = nil
      Self.logger.error("❌ [VideoPlayerViewModel] subtitle selection failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private func configureSubtitles(_ loadedSubtitles: [VideoSubtitle]) {
    subtitles = loadedSubtitles.filter { $0.url != nil }
    subtitleCueCache.removeAll()
    isSubtitleMenuVisible = false
    isSubtitleLoading = false
    isSubtitlesEnabled = false
    currentSubtitleText = nil
    selectedSubtitleLanguage = defaultSubtitle()?.language
  }

  private func defaultSubtitle() -> VideoSubtitle? {
    subtitles.first(where: \.isDefault) ?? subtitles.first
  }

  private func loadSubtitleIfNeeded(language: String) async throws {
    guard subtitleCueCache[language] == nil else { return }
    guard let subtitle = subtitles.first(where: { $0.language == language }), let url = subtitle.url else {
      throw VideoPlayerServiceError.invalidRequest
    }

    isSubtitleLoading = true
    defer { isSubtitleLoading = false }
    subtitleCueCache[language] = try await service.loadSubtitleCues(from: url)
  }

  private func updateCurrentSubtitle(for time: Double) {
    guard
      isSubtitlesEnabled,
      let selectedSubtitleLanguage,
      let cues = subtitleCueCache[selectedSubtitleLanguage]
    else {
      currentSubtitleText = nil
      return
    }

    currentSubtitleText = cues.first { cue in
      cue.startTime <= time && time < cue.endTime
    }?.text
  }

  private func handleSelectQuality(_ label: String) async {
    guard label != selectedQuality else {
      isQualityMenuVisible = false
      return
    }

    cancelPendingQualityChange()

    let previousQuality = selectedQuality
    let wasPlaying: Bool
    if case .ready(let playing) = playerPhase {
      wasPlaying = playing
    } else {
      wasPlaying = false
    }

    selectedQuality = label
    pendingQualityLabel = label
    isQualityMenuVisible = false

    do {
      let stream = try await service.loadStream(videoId: video.id)
      guard let url = qualityURL(for: label, in: stream) ?? stream.streamURL else {
        selectedQuality = previousQuality
        pendingQualityLabel = nil
        playerPhase = .error(message: VideoPlayerServiceError.invalidResponse.errorDescription ?? "잠시 후 다시 시도해 주세요.")
        return
      }
      Self.logger.info("ℹ️ [VideoPlayerViewModel] quality change requested label=\(label, privacy: .public)")

      let bufferedEnd = min(currentBufferedEnd(), duration - 0.05)
      let remaining = bufferedEnd - currentTime

      if remaining < HLSPolicy.deferThreshold {
        pendingQualityLabel = nil
        swapPlayerItem(url: url, resumeTime: currentTime, play: wasPlaying)
      } else {
        scheduleDeferredQualitySwap(label: label, url: url, bufferedEnd: bufferedEnd)
      }
    } catch {
      selectedQuality = previousQuality
      pendingQualityLabel = nil
      let message = (error as? VideoPlayerServiceError)?.errorDescription
        ?? VideoPlayerServiceError.serverError.errorDescription
        ?? "잠시 후 다시 시도해 주세요."
      playerPhase = .error(message: message)
      Self.logger.error("❌ [VideoPlayerViewModel] quality change failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private func currentBufferedEnd() -> Double {
    guard let item = player?.currentItem else { return 0 }
    let current = player?.currentTime().seconds ?? 0
    return item.loadedTimeRanges
      .map { $0.timeRangeValue }
      .filter { $0.start.seconds <= current + 0.5 }
      .map { ($0.start + $0.duration).seconds }
      .max() ?? current
  }

  private func cancelPendingQualityChange() {
    guard let pending = pendingQuality else { return }
    if let token = pending.boundaryToken {
      player?.removeTimeObserver(token)
    }
    pending.preloadTask?.cancel()
    player?.currentItem?.preferredForwardBufferDuration = 0
    pendingQuality = nil
    pendingQualityLabel = nil
    Self.logger.info("ℹ️ [VideoPlayerViewModel] pending quality change cancelled")
  }

  private func scheduleDeferredQualitySwap(label: String, url: URL, bufferedEnd: Double) {
    guard let currentPlayer = player else { return }

    currentPlayer.currentItem?.preferredForwardBufferDuration = HLSPolicy.frozenBufferDuration

    var pending = PendingQualityChange(label: label, url: url, bufferedEnd: bufferedEnd)

    pending.preloadTask = Task { [weak self] in
      let asset = AVURLAsset(url: url)
      _ = try? await asset.load(.isPlayable)
      await MainActor.run { self?.pendingQuality?.loadedAsset = asset }
    }

    let triggerTime = max(bufferedEnd - HLSPolicy.boundaryLeadTime, currentTime + 0.1)
    let cmTime = CMTime(seconds: triggerTime, preferredTimescale: 600)

    let token = currentPlayer.addBoundaryTimeObserver(
      forTimes: [NSValue(time: cmTime)],
      queue: .main
    ) { [weak self] in
      Task { @MainActor [weak self] in self?.executePendingSwap() }
    }
    pending.boundaryToken = token

    pendingQuality = pending
    Self.logger.info("ℹ️ [VideoPlayerViewModel] deferred quality swap scheduled bufferedEnd=\(bufferedEnd, privacy: .public) label=\(label, privacy: .public)")
  }

  private func executePendingSwap() {
    guard let pending = pendingQuality, let currentPlayer = player else { return }

    if let token = pending.boundaryToken {
      currentPlayer.removeTimeObserver(token)
    }
    pending.preloadTask?.cancel()

    let cutTime = currentPlayer.currentTime().seconds
    let asset = pending.loadedAsset ?? AVURLAsset(url: pending.url)
    let newItem = AVPlayerItem(asset: asset)

    currentPlayer.currentItem?.preferredForwardBufferDuration = 0

    itemStatusObservation?.invalidate()
    itemStatusObservation = newItem.observe(\.status, options: [.new]) { [weak self] item, _ in
      guard let self else { return }
      Task { @MainActor in
        if case .failed = item.status {
          Self.logger.error("❌ [VideoPlayerViewModel] playerItem failed error=\(String(describing: item.error), privacy: .public)")
          self.playerPhase = .error(message: "재생 중 오류가 발생했습니다.")
        }
      }
    }

    currentPlayer.replaceCurrentItem(with: newItem)
    let target = CMTime(seconds: cutTime, preferredTimescale: 600)
    currentPlayer.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)

    if case .ready(true) = playerPhase {
      currentPlayer.play()
    }

    pendingQuality = nil
    pendingQualityLabel = nil
    Self.logger.info("ℹ️ [VideoPlayerViewModel] deferred quality swap executed cutTime=\(cutTime, privacy: .public) label=\(pending.label, privacy: .public)")
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

    if let pending = pendingQuality {
      cancelPendingQualityChange()
      swapPlayerItem(url: pending.url, resumeTime: time, play: { if case .ready(let p) = playerPhase { return p }; return false }())
      return
    }

    currentTime = time
    updateCurrentSubtitle(for: time)
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
        self.updateCurrentSubtitle(for: time.seconds)
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
    cancelPendingQualityChange()
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
    try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
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
