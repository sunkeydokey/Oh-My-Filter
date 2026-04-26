import SwiftUI

struct MainBannerCarouselSectionView: View {
  let state: MainSectionState<[MainBanner]>
  let retryAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      MainSectionHeaderView(
        title: "메인 배너",
        subtitle: "지금 확인할 만한 공지와 캠페인을 모아두었어요."
      )

      if let banners = state.value, banners.isEmpty == false {
        MainBannerCarouselView(banners: banners)
      } else {
        MainBannerFallbackView(state: state, retryAction: retryAction)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
