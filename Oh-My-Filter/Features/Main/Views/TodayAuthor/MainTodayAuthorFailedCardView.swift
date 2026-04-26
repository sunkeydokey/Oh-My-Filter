import SwiftUI

struct MainTodayAuthorFailedCardView: View {
  let message: String
  let retryAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("오늘의 작성자를 불러오지 못했어요.")
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.grayScale0.color)

      Text(message)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale60.color)
        .fixedSize(horizontal: false, vertical: true)

      Button("다시 시도", action: retryAction)
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
}
