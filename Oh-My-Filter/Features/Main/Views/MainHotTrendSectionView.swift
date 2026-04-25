import Kingfisher
import SwiftUI

struct MainHotTrendSectionView: View {
  let state: MainSectionLoadState
  let hotTrendFilters: [MainHotTrendFilter]
  let retryAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      MainSectionHeaderView(
        title: "핫 트렌드",
        subtitle: "반응이 좋은 필터를 지금 바로 살펴보세요."
      )

      if hotTrendFilters.isEmpty {
        fallbackView
      } else {
        ScrollView(.horizontal) {
          LazyHStack(spacing: 14) {
            ForEach(hotTrendFilters.indices, id: \.self) { index in
              hotTrendCard(index: index, item: hotTrendFilters[index])
            }
          }
          .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
      }
    }
  }

  @ViewBuilder
  private func hotTrendCard(index: Int, item: MainHotTrendFilter) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 10) {
        Text("#\(index + 1)")
          .font(TypographyToken.pretendardTitle1.font)
          .foregroundStyle(ColorToken.sesacFilterBrightTurquoise.color)

        Spacer(minLength: 0)

        Circle()
          .fill(ColorToken.grayScale90.color)
          .frame(width: 42, height: 42)
          .overlay {
            if let imageUrl = item.imageUrl {
              KFImage(imageUrl)
                .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
                .placeholder {
                  fallbackIcon
                }
                .resizable()
                .scaledToFill()
                .clipShape(.circle)
            } else {
              fallbackIcon
            }
          }
      }

      VStack(alignment: .leading, spacing: 6) {
        Text(item.title)
          .font(TypographyToken.pretendardBody1.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale0.color)
          .fixedSize(horizontal: false, vertical: true)

        if let creatorName = item.creatorName {
          Text(creatorName)
            .font(TypographyToken.pretendardBody3.font)
            .foregroundStyle(ColorToken.grayScale60.color)
        }
      }
    }
    .padding(16)
    .frame(width: 220, alignment: .leading)
    .background(ColorToken.brandDeepSprout.color)
    .clipShape(.rect(cornerRadius: 22))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }

  @ViewBuilder
  private var fallbackView: some View {
    switch state {
    case .loading, .idle:
      ScrollView(.horizontal) {
        LazyHStack(spacing: 14) {
          ForEach(0..<3, id: \.self) { _ in
            RoundedRectangle(cornerRadius: 22, style: .continuous)
              .fill(ColorToken.brandDeepSprout.color)
              .frame(width: 220, height: 160)
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
      Text("표시할 핫 트렌드가 아직 없어요.")
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.grayScale0.color)

      Text("새로운 필터가 올라오면 이 영역에 정리해 보여드릴게요.")
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale60.color)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ColorToken.brandDeepSprout.color)
    .clipShape(.rect(cornerRadius: 22))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }

  private func failedCard(message: String) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("핫 트렌드를 불러오지 못했어요.")
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
    .clipShape(.rect(cornerRadius: 22))
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }

  private var fallbackIcon: some View {
    Image(systemName: "sparkles")
      .font(.caption)
      .foregroundStyle(ColorToken.grayScale0.color)
      .frame(width: 42, height: 42)
      .background(ColorToken.grayScale75.color)
  }
}
