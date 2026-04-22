import SwiftUI

struct TypographyTokenRowView: View {
  let token: TypographyToken

  var body: some View {
    HStack(alignment: .firstTextBaseline, spacing: 12) {
      Text(token.roleTitle)
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.brandBlackSprout.color)
        .frame(width: 78, alignment: .leading)

      Text(token.sizeLabel)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale75.color)
        .frame(width: 48, alignment: .leading)

      Text(token.sampleText)
        .font(token.font)
        .foregroundStyle(ColorToken.brandBlackSprout.color)
        .frame(maxWidth: .infinity, alignment: .leading)
        .minimumScaleFactor(0.7)
    }
    .padding(.vertical, 4)
  }
}
