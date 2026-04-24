import SwiftUI

struct FilterInfoItemView: View {
  let title: String
  let value: String

  var body: some View {
    VStack(spacing: 4) {
      Text(value)
        .font(TypographyToken.pretendardCaption1.font)
        .bold()
        .foregroundStyle(ColorToken.grayScale0.color)
        .lineLimit(1)
        .minimumScaleFactor(0.75)

      Text(title)
        .font(TypographyToken.pretendardCaption2.font)
        .foregroundStyle(ColorToken.grayScale60.color)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity)
  }
}
