import AVFoundation
import SwiftUI

struct PostVideoPreviewView: View {
  let url: URL
  let isActive: Bool

  @State private var player: AVPlayer?
  @State private var playbackEndObserver: (any NSObjectProtocol)?
  @State private var pauseTask: Task<Void, Never>?

  var body: some View {
    ZStack {
      if let player {
        VideoPlayerLayerView(player: player)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ColorToken.brandBlackSprout.color
        Image(systemName: "play.fill")
          .font(.system(size: 28, weight: .semibold))
          .foregroundStyle(ColorToken.grayScale60.color)
      }
    }
    .task(id: isActive) {
      if isActive {
        await setupPlayer()
      } else {
        teardownPlayer()
      }
    }
    .onDisappear {
      teardownPlayer()
    }
  }

  private func setupPlayer() async {
    guard isActive, player == nil else { return }

    let asset = await AuthenticatedVideoAssetBuilder.makeAsset(url: url)
    guard isActive, Task.isCancelled == false else { return }

    let item = AVPlayerItem(asset: asset)
    let newPlayer = AVPlayer(playerItem: item)
    newPlayer.isMuted = true

    playbackEndObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { _ in
      newPlayer.seek(to: .zero)
      newPlayer.play()
    }

    player = newPlayer
    newPlayer.play()

    pauseTask = Task {
      try? await Task.sleep(for: .seconds(15))
      guard Task.isCancelled == false else { return }
      await MainActor.run {
        newPlayer.pause()
      }
    }
  }

  private func teardownPlayer() {
    pauseTask?.cancel()
    pauseTask = nil

    if let playbackEndObserver {
      NotificationCenter.default.removeObserver(playbackEndObserver)
      self.playbackEndObserver = nil
    }

    player?.pause()
    player = nil
  }
}
