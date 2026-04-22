import SwiftUI

struct ColorTokenSectionView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Color tokens")
        .font(TypographyToken.pretendardTitle1.font)
        .foregroundStyle(ColorToken.brandBlackSprout.color)

      VStack(spacing: 12) {
        ForEach(ColorToken.allCases, id: \.self) { token in
          ColorTokenSwatchView(token: token)
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ColorToken.grayScale0.color)
    .clipShape(.rect(cornerRadius: CornerRadiusToken.section.value))
    .overlay {
      RoundedRectangle(cornerRadius: CornerRadiusToken.section.value)
        .stroke(ColorToken.grayScale30.color, lineWidth: 1)
    }
  }
}
