import SwiftUI

struct MainBannerFallbackBackgroundView: View {
  var body: some View {
    LinearGradient(
      colors: [
        ColorToken.brandDeepSprout.color,
        ColorToken.sesacFilterDeepTurquoise.color
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
