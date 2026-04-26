import SwiftUI

struct MainTodayAuthorThumbnailFallbackView: View {
  let symbol: String

  var body: some View {
    LinearGradient(
      colors: [
        ColorToken.grayScale75.color,
        ColorToken.brandBlackSprout.color
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
    .overlay {
      Image(systemName: symbol)
        .font(.system(size: 20, weight: .semibold))
        .foregroundStyle(ColorToken.grayScale0.color.opacity(0.75))
        .accessibilityHidden(true)
    }
  }
}
