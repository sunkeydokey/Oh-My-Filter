import SwiftUI

struct ChatHeaderView: View {
  let title: String
  let subtitle: String
  let onBack: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onBack) {
        Image(systemName: "chevron.left")
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(ColorToken.grayScale0.color)
          .frame(width: 40, height: 40)
          .background(ColorToken.grayScale100.color, in: .rect(cornerRadius: 20))
          .overlay {
            RoundedRectangle(cornerRadius: 20)
              .stroke(ColorToken.grayScale90.color.opacity(0.5), lineWidth: 1)
          }
      }

      ChatAvatarView(text: title, size: 48)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(TypographyToken.mulgyeolBody1.font)
          .foregroundStyle(ColorToken.grayScale0.color)
          .lineLimit(1)

        Text(subtitle)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(height: 64)
    .padding(.horizontal, 20)
  }
}
