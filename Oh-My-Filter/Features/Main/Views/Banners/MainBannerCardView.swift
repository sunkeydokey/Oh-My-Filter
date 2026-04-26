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

      LinearGradient(
        colors: [
          .clear,
          ColorToken.brandBlackSprout.color.opacity(0.84)
        ],
        startPoint: .top,
        endPoint: .bottom
      )

      VStack(alignment: .leading, spacing: 6) {
        Text(banner.title)
          .font(TypographyToken.pretendardTitle1.font)
          .foregroundStyle(ColorToken.grayScale0.color)
          .fixedSize(horizontal: false, vertical: true)

        Text(banner.subtitle)
          .font(TypographyToken.pretendardBody3.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipShape(.rect(cornerRadius: MainBannerLayout.cornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: MainBannerLayout.cornerRadius, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }
}
