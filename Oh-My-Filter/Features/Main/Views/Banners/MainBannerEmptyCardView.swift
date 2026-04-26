import SwiftUI

struct MainBannerEmptyCardView: View {
  var body: some View {
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
    .clipShape(.rect(cornerRadius: MainBannerLayout.cornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: MainBannerLayout.cornerRadius, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }
}
