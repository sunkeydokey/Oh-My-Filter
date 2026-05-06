import SwiftUI

struct MainHotTrendLoadingView: View {
  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 16) {
        ForEach(0..<3, id: \.self) { _ in
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(ColorToken.brandDeepSprout.color)
            .frame(width: 200, height: 240)
            .overlay {
              ProgressView()
                .tint(ColorToken.mainAccent.color)
            }
        }
      }
    }
    .frame(maxWidth: .infinity)
    .scrollIndicators(.hidden)
  }
}
