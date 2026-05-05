import AVFoundation
import SwiftUI
import UIKit

struct VideoPlayerLayerView: UIViewRepresentable {
  let player: AVPlayer?

  func makeUIView(context: Context) -> PlayerUIView {
    let view = PlayerUIView()
    view.backgroundColor = .clear
    return view
  }

  func updateUIView(_ uiView: PlayerUIView, context: Context) {
    uiView.playerLayer.player = player
  }
}

final class PlayerUIView: UIView {
  override class var layerClass: AnyClass {
    AVPlayerLayer.self
  }

  var playerLayer: AVPlayerLayer {
    layer as! AVPlayerLayer
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    playerLayer.videoGravity = .resizeAspectFill
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
