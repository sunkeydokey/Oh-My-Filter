import SwiftUI

struct MainBannerCarouselView: View {
  let banners: [MainBanner]

  var body: some View {
    TabView {
      ForEach(banners) { banner in
        MainBannerCardView(banner: banner)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 110)
    .tabViewStyle(.page(indexDisplayMode: .never))
  }
}
