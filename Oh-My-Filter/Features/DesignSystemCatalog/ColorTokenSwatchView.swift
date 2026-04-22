import SwiftUI

struct ColorTokenSwatchView: View {
  let token: ColorToken

  var body: some View {
    HStack(spacing: 12) {
      RoundedRectangle(cornerRadius: 12)
        .fill(token.color)
        .frame(width: 56, height: 56)
        .overlay {
          RoundedRectangle(cornerRadius: 12)
            .stroke(ColorToken.grayScale30.color, lineWidth: 1)
        }

      VStack(alignment: .leading, spacing: 4) {
        Text(token.figmaName)
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.brandBlackSprout.color)

        Text(token.hexValue)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale75.color)
      }

      Spacer(minLength: 0)
    }
  }
}
