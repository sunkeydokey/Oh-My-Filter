import SwiftUI

struct MainBannerLoadingView: View {
  var body: some View {
    TabView {
      RoundedRectangle(cornerRadius: MainBannerLayout.cornerRadius, style: .continuous)
        .fill(ColorToken.brandDeepSprout.color)
        .overlay {
          ProgressView()
            .tint(ColorToken.sesacFilterBrightTurquoise.color)
        }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 160)
    .tabViewStyle(.page(indexDisplayMode: .never))
  }
}
