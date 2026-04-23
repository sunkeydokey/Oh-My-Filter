import SwiftUI

struct SignupTextFieldSection<Field: View>: View {
  let title: String
  let description: String?
  let message: String?
  let isSuccess: Bool
  @ViewBuilder private let field: Field

  init(
    title: String,
    description: String? = nil,
    message: String? = nil,
    isSuccess: Bool = false,
    @ViewBuilder field: () -> Field
  ) {
    self.title = title
    self.description = description
    self.message = message
    self.isSuccess = isSuccess
    self.field = field()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      VStack(alignment: .leading, spacing: 6) {
        Text(title)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale60.color)

        field
          .font(TypographyToken.pretendardBody1.font)
          .foregroundStyle(ColorToken.grayScale0.color)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background(ColorToken.brandDeepSprout.color)
      .clipShape(.rect(cornerRadius: 15))

      if let description {
        Text(description)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale60.color)
      }

      Group {
        if let message {
          SignupStatusMessageView(message: message, isSuccess: isSuccess)
        } else {
          Text(" ")
            .font(TypographyToken.pretendardCaption1.font)
            .hidden()
            .accessibilityHidden(true)
        }
      }
    }
  }
}
