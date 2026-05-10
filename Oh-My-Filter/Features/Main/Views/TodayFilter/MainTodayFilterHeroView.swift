import Kingfisher
import SwiftUI

struct MainTodayFilterHeroView: View {
  let todayFilter: MainTodayFilter
  let selectionAction: (String) -> Void

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      Group {
        if let imageUrl = todayFilter.imageUrl {
          KFImage(imageUrl)
            .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
            .placeholder {
              MainTodayFilterHeroFallbackGradientView()
            }
            .resizable()
            .scaledToFill()
        } else {
          MainTodayFilterHeroFallbackGradientView()
        }
      }
      .frame(maxWidth: .infinity)
      .frame(height: MainTodayFilterLayout.heroHeight)
      .clipped()

      LinearGradient(
        colors: [
          .clear,
          ColorToken.brandBlackSprout.color.opacity(0.12),
          ColorToken.brandBlackSprout.color.opacity(0.94),
        ],
        startPoint: .top,
        endPoint: .bottom
      )

      VStack(alignment: .leading, spacing: 18) {
        HStack {
          Spacer(minLength: 0)

          Button {
            selectionAction(todayFilter.id)
          } label: {
            Text("사용해보기")
              .font(.custom(TypographyToken.pretendardBody3.fontName, size: 12, relativeTo: .caption))
              .foregroundStyle(ColorToken.grayScale60.color)
              .padding(.horizontal, 12)
              .padding(.vertical, 7)
              .background(
                ColorToken.grayScale75.color.opacity(0.5),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
              )
              .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                  .stroke(ColorToken.grayScale75.color.opacity(0.85), lineWidth: 1)
              )
              .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
          }
          .padding(.top, 64)
        }

        Spacer()

        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 8) {
            Text("오늘의 필터 소개")
              .font(.custom(TypographyToken.pretendardBody3.fontName, size: 13, relativeTo: .callout))
              .foregroundStyle(ColorToken.grayScale60.color)

            Text(todayFilter.title)
              .font(TypographyToken.mulgyeolTitle1.font)
              .foregroundStyle(ColorToken.grayScale0.color)
              .fixedSize(horizontal: false, vertical: true)

            if let todayFilterSubtitle = todayFilter.subtitle {
              Text(todayFilterSubtitle)
                .font(TypographyToken.mulgyeolTitle1.font)
                .lineSpacing(5)
                .foregroundStyle(ColorToken.grayScale45.color)
                .fixedSize(horizontal: false, vertical: true)
            }
          }

          Text(todayFilter.description)
            .font(.custom(TypographyToken.pretendardBody3.fontName, size: 12, relativeTo: .subheadline))
            .lineSpacing(5)
            .foregroundStyle(ColorToken.grayScale45.color)
            .fixedSize(horizontal: false, vertical: true)

          MainTodayFilterCategoryStripView()
        }
      }
      .padding(.horizontal, MainViewLayout.contentHorizontalInset)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: .infinity)
  }
}
