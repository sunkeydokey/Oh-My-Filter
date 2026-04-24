import SwiftUI

struct FilterDetailStatsView: View {
  let detail: FilterDetail

  var body: some View {
    HStack(spacing: 8) {
      FilterDetailStatCardView(title: "다운로드", value: detail.downloadCountText)
      FilterDetailStatCardView(title: "찜하기", value: detail.likeCountText)
    }
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
    .frame(width: 99, height: 56)
    .background(ColorToken.brandDeepSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}
