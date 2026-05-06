import AVFoundation
import SwiftUI

struct PostVideoPlayerView: View {
  let url: URL

  @State private var player: AVPlayer?
  @State private var isPlaying = false
  @State private var currentTime: Double = 0
  @State private var duration: Double = 1
  @State private var isSeeking = false
  @State private var timeObserver: Any?

  var body: some View {
    ZStack {
      ColorToken.brandBlackSprout.color

      if let player {
        VideoPlayerLayerView(player: player)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }

      controls
    }
    .frame(maxWidth: .infinity)
    .frame(height: 210)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .task {
      await setupPlayer()
    }
    .onDisappear {
      teardownPlayer()
    }
  }

  private var controls: some View {
    VStack {
      Spacer()

      // Play/Pause center button
      Button {
        togglePlay()
      } label: {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: 22))
          .foregroundStyle(ColorToken.grayScale30.color)
          .frame(width: 56, height: 56)
          .background(Color.black.opacity(0.7))
          .clipShape(Circle())
      }
      .buttonStyle(.plain)

      Spacer()

      // Progress bar
      VStack(spacing: 2) {
        HStack {
          Text(formatTime(currentTime))
          Spacer()
          Text(formatTime(duration))
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(ColorToken.grayScale30.color)
        .padding(.horizontal, 14)

        Slider(
          value: $currentTime,
          in: 0...max(duration, 1),
          onEditingChanged: { editing in
            isSeeking = editing
            if !editing, let player {
              let target = CMTime(seconds: currentTime, preferredTimescale: 600)
              player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
            }
          }
        )
        .tint(ColorToken.grayScale30.color)
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
      }
      .background(LinearGradient(colors: [.clear, Color.black.opacity(0.7)], startPoint: .top, endPoint: .bottom))
    }
  }

  private func setupPlayer() async {
    let asset = await AuthenticatedVideoAssetBuilder.makeAsset(url: url)
    let item = AVPlayerItem(asset: asset)
    let newPlayer = AVPlayer(playerItem: item)
    newPlayer.isMuted = false

    // duration
    if let seconds = try? await asset.load(.duration).seconds, seconds.isFinite, seconds > 0 {
      duration = seconds
    }

    timeObserver = newPlayer.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
      queue: .main
    ) { [weak newPlayer] time in
      Task { @MainActor in
        guard !isSeeking else { return }
        currentTime = time.seconds
        if let d = newPlayer?.currentItem?.duration.seconds, d.isFinite, d > 0 {
          duration = d
        }
      }
    }

    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { _ in
      Task { @MainActor in
        isPlaying = false
        currentTime = 0
      }
    }

    player = newPlayer
  }

  private func teardownPlayer() {
    if let obs = timeObserver {
      player?.removeTimeObserver(obs)
      timeObserver = nil
    }
    player?.pause()
    player = nil
  }

  private func togglePlay() {
    guard let player else { return }
    if isPlaying {
      player.pause()
      isPlaying = false
    } else {
      if currentTime >= duration - 0.5 {
        player.seek(to: .zero)
        currentTime = 0
      }
      player.play()
      isPlaying = true
    }
  }

  private func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let total = Int(seconds)
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}
