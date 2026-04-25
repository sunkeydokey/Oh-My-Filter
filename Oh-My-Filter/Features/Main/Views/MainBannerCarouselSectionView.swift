import Kingfisher
import SwiftUI

struct MainBannerCarouselSectionView: View {
  let state: MainSectionLoadState
  let banners: [MainBanner]
  let retryAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      MainSectionHeaderView(
        title: "메인 배너",
        subtitle: "지금 확인할 만한 공지와 캠페인을 모아두었어요."
      )

      if banners.isEmpty {
        fallbackView
      } else {
        ScrollView(.horizontal) {
          LazyHStack(spacing: 14) {
            ForEach(banners, id: \.id) { banner in
              bannerCard(banner)
            }
          }
          .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
      }
    }
  }

  @ViewBuilder
  private func bannerCard(_ banner: MainBanner) -> some View {
    ZStack(alignment: .bottomLeading) {
      Group {
        if let imageUrl = banner.imageUrl {
          KFImage(imageUrl)
            .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
            .placeholder {
              fallbackBannerBackground
            }
            .resizable()
            .scaledToFill()
        } else {
          fallbackBannerBackground
        }
      }
      .frame(width: 300, height: 160)
      .clipped()

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
      .frame(width: 300, alignment: .leading)
    }
    .clipShape(.rect(cornerRadius: 24))
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }

  @ViewBuilder
  private var fallbackView: some View {
    switch state {
    case .loading, .idle:
      ScrollView(.horizontal) {
        LazyHStack(spacing: 14) {
          ForEach(0..<2, id: \.self) { _ in
            RoundedRectangle(cornerRadius: 24, style: .continuous)
              .fill(ColorToken.brandDeepSprout.color)
              .frame(width: 300, height: 160)
              .overlay {
                ProgressView()
                  .tint(ColorToken.sesacFilterBrightTurquoise.color)
              }
          }
        }
      }
      .scrollIndicators(.hidden)
    case let .failed(message):
      failedCard(message: message)
    case .loaded:
      emptyCard
    }
  }

  private var emptyCard: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("표시할 배너가 아직 없어요.")
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.grayScale0.color)

      Text("배너가 추가되면 이 자리에서 바로 확인할 수 있어요.")
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale60.color)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ColorToken.brandDeepSprout.color)
    .clipShape(.rect(cornerRadius: 24))
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }

  private func failedCard(message: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("배너를 불러오지 못했어요.")
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.grayScale0.color)

      Text(message)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale60.color)
        .fixedSize(horizontal: false, vertical: true)

      Button("다시 시도") {
        retryAction()
      }
      .buttonStyle(.bordered)
      .tint(ColorToken.sesacFilterBrightTurquoise.color)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ColorToken.brandDeepSprout.color)
    .clipShape(.rect(cornerRadius: 24))
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }

  private var fallbackBannerBackground: some View {
    LinearGradient(
      colors: [
        ColorToken.brandDeepSprout.color,
        ColorToken.sesacFilterDeepTurquoise.color
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}
