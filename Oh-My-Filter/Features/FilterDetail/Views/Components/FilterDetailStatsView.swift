import SwiftUI

struct FilterDetailStatsView: View {
  let detail: FilterDetail
  let onToggleLike: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      FilterDetailStatCardView(title: "다운로드", value: detail.downloadCountText)
      FilterDetailStatCardView(title: "찜하기", value: detail.likeCountText)
      FilterDetailFavoriteButton(
        isLiked: detail.isLiked,
        action: onToggleLike
      )
    }
  }
}

private struct FilterDetailFavoriteButton: View {
  let isLiked: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: isLiked ? "heart.fill" : "heart")
          .font(.system(size: 16, weight: .semibold))

        Text("찜하기")
          .font(TypographyToken.pretendardCaption1.font.weight(.bold))
      }
      .foregroundStyle(isLiked ? ColorToken.grayScale15.color : ColorToken.grayScale45.color)
      .padding(.horizontal, 14)
      .frame(height: 42)
      .background(
        isLiked ? ColorToken.mainAccent.color : ColorToken.brandBlackSprout.color,
        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
      )
      .buttonHitArea(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}

struct FilterDetailStatCardView: View {
  let title: String
  let value: String

  var body: some View {
    VStack(spacing: 4) {
      Text(title)
        .font(TypographyToken.pretendardCaption1.font)
        .bold()
        .foregroundStyle(ColorToken.grayScale60.color)

      Text(value)
        .font(TypographyToken.pretendardBody1.font)
        .bold()
        .foregroundStyle(ColorToken.grayScale0.color)
    }
    .frame(maxWidth: .infinity, minHeight: 56)
    .background(ColorToken.brandDeepSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}
