import SwiftUI

struct AuthSocialLoginButton: View {
  let title: String
  let systemImage: String
  let font: Font
  let emphasized: Bool
  let fillColor: Color
  let foregroundColor: Color
  let borderColor: Color?
  let action: (() async -> Void)?

  init(
    title: String,
    systemImage: String,
    font: Font = TypographyToken.pretendardBody2.font,
    emphasized: Bool = true,
    fillColor: Color,
    foregroundColor: Color,
    borderColor: Color? = nil,
    action: (() async -> Void)? = nil
  ) {
    self.title = title
    self.systemImage = systemImage
    self.font = font
    self.emphasized = emphasized
    self.fillColor = fillColor
    self.foregroundColor = foregroundColor
    self.borderColor = borderColor
    self.action = action
  }

  var body: some View {
    Button {
      Task {
        await action?()
      }
    } label: {
      Label(title, systemImage: systemImage)
        .font(font)
        .foregroundStyle(foregroundColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(fillColor)
        .overlay {
          if let borderColor {
            RoundedRectangle(cornerRadius: CornerRadiusToken.section.value)
              .stroke(borderColor, lineWidth: 1)
          }
        }
        .buttonHitArea(RoundedRectangle(cornerRadius: CornerRadiusToken.section.value))
        .clipShape(.rect(cornerRadius: CornerRadiusToken.section.value))
        .modifier(AuthSocialLoginButtonEmphasisModifier(isEmphasized: emphasized))
    }
    .buttonStyle(.plain)
  }
}

private struct AuthSocialLoginButtonEmphasisModifier: ViewModifier {
  let isEmphasized: Bool

  func body(content: Content) -> some View {
    if isEmphasized {
      content.bold()
    } else {
      content
    }
  }
}
