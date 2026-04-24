import SwiftUI

struct AuthNavigationPromptView: View {
  let prompt: String
  let actionTitle: String
  let action: () -> Void

  var body: some View {
    HStack(spacing: 4) {
      Text(prompt)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale60.color)

      Button(actionTitle, action: action)
        .buttonStyle(.plain)
        .font(TypographyToken.pretendardBody2.font)
        .bold()
        .foregroundStyle(ColorToken.grayScale0.color)
    }
    .frame(maxWidth: .infinity, alignment: .center)
  }
}
