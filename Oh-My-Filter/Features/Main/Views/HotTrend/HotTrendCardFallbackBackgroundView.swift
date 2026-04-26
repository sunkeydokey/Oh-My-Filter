import SwiftUI

struct HotTrendCardFallbackBackgroundView: View {
  var body: some View {
    LinearGradient(
      colors: [
        ColorToken.brandDeepSprout.color,
        ColorToken.grayScale90.color.opacity(0.95)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
