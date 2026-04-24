import SwiftUI

struct AuthSubmitSection: View {
  let title: String
  let isSubmitting: Bool
  let isEnabled: Bool
  let message: String?
  let isSuccessMessage: Bool
  let submitAction: () async -> Void

  init(
    title: String,
    isSubmitting: Bool,
    isEnabled: Bool,
    message: String? = nil,
    isSuccessMessage: Bool = false,
    submitAction: @escaping () async -> Void
  ) {
    self.title = title
    self.isSubmitting = isSubmitting
    self.isEnabled = isEnabled
    self.message = message
    self.isSuccessMessage = isSuccessMessage
    self.submitAction = submitAction
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Button {
        Task {
          await submitAction()
        }
      } label: {
        Text(title)
          .font(TypographyToken.pretendardBody1.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale0.color)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 15)
      }
      .buttonStyle(.plain)
      .background(isEnabled ? ColorToken.sesacFilterBrightTurquoise.color : ColorToken.grayScale75.color)
      .clipShape(.rect(cornerRadius: CornerRadiusToken.section.value))
      .disabled(isEnabled == false)

      if isSubmitting {
        ProgressView("\(title) 요청 중…")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale60.color)
      }

      if let message {
        AuthStatusMessageView(message: message, isSuccess: isSuccessMessage)
      }
    }
  }
}
