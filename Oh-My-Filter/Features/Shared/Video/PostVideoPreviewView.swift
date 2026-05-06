import AVFoundation
import SwiftUI

struct PostVideoPreviewView: View {
  let url: URL

  @State private var player: AVPlayer?

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
    .task {
      await setupPlayer()
    }
    .onDisappear {
      teardownPlayer()
    }
  }

  private func setupPlayer() async {
    let asset = await AuthenticatedVideoAssetBuilder.makeAsset(url: url)
    let item = AVPlayerItem(asset: asset)
    let newPlayer = AVPlayer(playerItem: item)
    newPlayer.isMuted = true

    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { _ in
      newPlayer.seek(to: .zero)
      newPlayer.play()
    }

    player = newPlayer
    newPlayer.play()

    // 15초 후 정지
    Task {
      try? await Task.sleep(for: .seconds(15))
      await MainActor.run {
        newPlayer.pause()
      }
    }
  }

  private func teardownPlayer() {
    player?.pause()
    player = nil
  }
}
