import Kingfisher
import SwiftUI

struct MainTodayAuthorSectionView: View {
  let state: MainSectionLoadState
  let todayAuthor: MainTodayAuthor?
  let retryAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      MainSectionHeaderView(
        title: "오늘의 작성자",
        subtitle: "필터를 만든 사람의 분위기를 함께 살펴보세요."
      )

      if let todayAuthor {
        authorCard(todayAuthor)
      } else {
        fallbackView
      }
    }
  }

  @ViewBuilder
  private func authorCard(_ todayAuthor: MainTodayAuthor) -> some View {
    HStack(alignment: .center, spacing: 14) {
      Circle()
        .fill(ColorToken.grayScale90.color)
        .frame(width: 72, height: 72)
        .overlay {
          if let profileImageUrl = todayAuthor.profileImageUrl {
            KFImage(profileImageUrl)
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

      VStack(alignment: .leading, spacing: 6) {
        Text(todayAuthor.nick)
          .font(TypographyToken.pretendardTitle1.font)
          .foregroundStyle(ColorToken.grayScale0.color)

        Text(todayAuthor.introduction ?? "오늘의 작업 분위기를 소개하는 작성자예요.")
          .font(TypographyToken.pretendardBody3.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 0)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ColorToken.brandDeepSprout.color)
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
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(ColorToken.brandDeepSprout.color)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 108)
        .overlay {
          ProgressView()
            .tint(ColorToken.sesacFilterBrightTurquoise.color)
        }
        .overlay(
          RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
        )
    case let .failed(message):
      failedCard(message: message)
    case .loaded:
      EmptyView()
    }
  }

  private func failedCard(message: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("오늘의 작성자를 불러오지 못했어요.")
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

  private var fallbackAvatar: some View {
    Image(systemName: "person.fill")
      .font(.title3)
      .foregroundStyle(ColorToken.grayScale0.color)
      .frame(width: 72, height: 72)
      .background(ColorToken.grayScale75.color)
  }
}
