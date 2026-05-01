import Kingfisher
import SwiftUI

struct MainBannerCardView: View {
  let banner: MainBanner

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      MainBannerFallbackBackgroundView()

      Group {
        if let imageUrl = banner.imageUrl {
          KFImage(imageUrl)
            .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
            .placeholder {
              MainBannerFallbackBackgroundView()
            }
            .resizable()
            .aspectRatio(contentMode: .fit)
        } else {
          MainBannerFallbackBackgroundView()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .clipShape(.rect(cornerRadius: MainBannerLayout.cornerRadius))
      .accessibilityLabel(banner.title)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipShape(.rect(cornerRadius: MainBannerLayout.cornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: MainBannerLayout.cornerRadius, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }
}
