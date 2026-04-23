import SwiftUI

struct CustomAlertView: View {
  let title: String
  let message: String
  let cancelTitle: String
  let confirmTitle: String
  let onCancel: () -> Void
  let onConfirm: () -> Void

  var body: some View {
    ZStack {
      ColorToken.grayScale100.color
        .opacity(0.94)
        .ignoresSafeArea()

      VStack(alignment: .leading, spacing: 14) {
        Text(title)
          .font(TypographyToken.pretendardTitle1.font)
          .foregroundStyle(ColorToken.grayScale0.color)

        Text(message)
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .frame(maxWidth: .infinity, alignment: .leading)
          .fixedSize(horizontal: false, vertical: true)

        HStack(spacing: 10) {
          Button(cancelTitle, action: onCancel)
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale60.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(ColorToken.brandDeepSprout.color)
            .clipShape(.rect(cornerRadius: CornerRadiusToken.section.value))

          Button(confirmTitle, action: onConfirm)
            .font(TypographyToken.pretendardBody2.font)
            .bold()
            .foregroundStyle(ColorToken.grayScale0.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(ColorToken.sesacFilterBrightTurquoise.color)
            .clipShape(.rect(cornerRadius: CornerRadiusToken.section.value))
        }
        .buttonStyle(.plain)
      }
      .padding(.top, 18)
      .padding(.horizontal, 16)
      .padding(.bottom, 14)
      .frame(maxWidth: 320, alignment: .leading)
      .background(ColorToken.brandBlackSprout.color)
      .overlay {
        RoundedRectangle(cornerRadius: CornerRadiusToken.section.value)
          .stroke(ColorToken.grayScale90.color.opacity(0.85), lineWidth: 1)
      }
      .clipShape(.rect(cornerRadius: CornerRadiusToken.section.value))
      .padding(.horizontal, 24)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

#Preview {
  CustomAlertView(
    title: "회원가입이 완료되었습니다!",
    message: "프로필을 작성할까요?",
    cancelTitle: "나중에 할래요",
    confirmTitle: "지금 할래요",
    onCancel: {},
    onConfirm: {}
  )
}
