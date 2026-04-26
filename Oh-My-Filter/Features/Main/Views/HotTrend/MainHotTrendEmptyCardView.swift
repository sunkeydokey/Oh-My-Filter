import SwiftUI

struct MainHotTrendEmptyCardView: View {
  var body: some View {
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
}
