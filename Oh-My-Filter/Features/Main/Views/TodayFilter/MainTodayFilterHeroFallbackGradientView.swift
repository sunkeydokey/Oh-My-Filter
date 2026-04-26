import SwiftUI

struct MainTodayFilterHeroFallbackGradientView: View {
  var body: some View {
    LinearGradient(
      colors: [
        ColorToken.brandDeepSprout.color,
        ColorToken.brandBlackSprout.color
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
