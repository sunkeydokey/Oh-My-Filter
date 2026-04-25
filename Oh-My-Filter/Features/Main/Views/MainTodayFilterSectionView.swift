import Kingfisher
import SwiftUI

struct MainTodayFilterSectionView: View {
  let state: MainSectionLoadState
  let todayFilter: MainTodayFilter?
  let retryAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      MainSectionHeaderView(
        title: "오늘의 필터",
        subtitle: "가장 먼저 확인해야 할 추천 콘텐츠예요."
      )

      if let todayFilter {
        todayFilterCard(todayFilter)
      } else {
        fallbackView
      }
    }
  }

  @ViewBuilder
  private func todayFilterCard(_ todayFilter: MainTodayFilter) -> some View {
    ZStack(alignment: .bottomLeading) {
      Group {
        if let imageUrl = todayFilter.imageUrl {
          KFImage(imageUrl)
            .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
            .placeholder {
              fallbackGradient
            }
            .resizable()
            .scaledToFill()
        } else {
          fallbackGradient
        }
      }
      .frame(maxWidth: .infinity)
      .frame(minHeight: 260)
      .clipped()

      LinearGradient(
        colors: [
          .clear,
          ColorToken.brandBlackSprout.color.opacity(0.18),
          ColorToken.brandBlackSprout.color.opacity(0.92)
        ],
        startPoint: .top,
        endPoint: .bottom
      )

      VStack(alignment: .leading, spacing: 12) {
        Text("TODAY")
          .font(TypographyToken.pretendardCaption1.font)
          .bold()
          .foregroundStyle(ColorToken.sesacFilterBrightTurquoise.color)
          .padding(.vertical, 6)
          .padding(.horizontal, 10)
          .background(ColorToken.grayScale0.color.opacity(0.12), in: Capsule())

        VStack(alignment: .leading, spacing: 8) {
          Text(todayFilter.title)
            .font(TypographyToken.mulgyeolBody1.font)
            .foregroundStyle(ColorToken.grayScale0.color)
            .fixedSize(horizontal: false, vertical: true)

          Text(todayFilter.subtitle)
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .fixedSize(horizontal: false, vertical: true)
        }

        if let creatorName = todayFilter.creatorName {
          HStack(spacing: 10) {
            Circle()
              .fill(ColorToken.grayScale90.color)
              .frame(width: 34, height: 34)
              .overlay {
                if let creatorProfileImageUrl = todayFilter.creatorProfileImageUrl {
                  KFImage(creatorProfileImageUrl)
                    .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
                    .placeholder {
                      fallbackAvatar
                    }
                    .resizable()
                    .scaledToFill()
                    .clipShape(.circle)
                } else {
                  fallbackAvatar
                }
              }

            Text(creatorName)
              .font(TypographyToken.pretendardBody3.font)
              .foregroundStyle(ColorToken.grayScale0.color)
          }
        }
      }
      .padding(20)
    }
    .clipShape(.rect(cornerRadius: 28))
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }

  private var fallbackView: some View {
    Group {
      switch state {
      case .loading, .idle:
        loadingCard
      case let .failed(message):
        failedCard(message: message)
      case .loaded:
        loadingCard
      }
    }
  }

  private var loadingCard: some View {
    RoundedRectangle(cornerRadius: 28, style: .continuous)
      .fill(ColorToken.brandDeepSprout.color)
      .frame(maxWidth: .infinity)
      .frame(minHeight: 260)
      .overlay {
        ProgressView()
          .tint(ColorToken.sesacFilterBrightTurquoise.color)
      }
      .overlay(
        RoundedRectangle(cornerRadius: 28, style: .continuous)
          .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
      )
  }

  private func failedCard(message: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("오늘의 필터를 불러오지 못했어요.")
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.grayScale0.color)

      Text(message)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale60.color)
        .fixedSize(horizontal: false, vertical: true)

      Button("다시 시도") {
        retryAction()
      }
      .buttonStyle(.borderedProminent)
      .tint(ColorToken.sesacFilterBrightTurquoise.color)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ColorToken.brandDeepSprout.color)
    .clipShape(.rect(cornerRadius: 28))
    .overlay(
      RoundedRectangle(cornerRadius: 28, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }

  private var fallbackGradient: some View {
    LinearGradient(
      colors: [
        ColorToken.brandDeepSprout.color,
        ColorToken.brandBlackSprout.color
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private var fallbackAvatar: some View {
    Image(systemName: "person.fill")
      .font(.caption)
      .foregroundStyle(ColorToken.grayScale0.color)
      .frame(width: 34, height: 34)
      .background(ColorToken.grayScale75.color)
  }
}
