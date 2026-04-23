import SwiftUI

struct SignupSubmitSection: View {
  let isSubmitting: Bool
  let isEnabled: Bool
  let message: String?
  let submitAction: () async -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Button {
        Task {
          await submitAction()
        }
      } label: {
        Text("회원가입")
          .font(TypographyToken.pretendardBody1.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale0.color)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 15)
      }
      .buttonStyle(.plain)
      .background(isEnabled ? ColorToken.sesacFilterBrightTurquoise.color : ColorToken.grayScale75.color)
      .clipShape(.rect(cornerRadius: 15))
      .disabled(isEnabled == false)

      if isSubmitting {
        ProgressView("회원가입 요청 중…")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale60.color)
      }

      if let message {
        SignupStatusMessageView(
          message: message,
          isSuccess: message == "회원가입이 완료되었어요."
        )
      }
    }
  }
}
