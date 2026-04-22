import SwiftUI

struct IconTokenChipView: View {
  let token: IconToken

  var body: some View {
    VStack(spacing: 8) {
      RoundedRectangle(cornerRadius: 12)
        .fill(ColorToken.grayScale15.color)
        .frame(height: 56)
        .overlay {
          Image(systemName: token.symbolName)
            .font(.system(size: 20, weight: .medium))
            .foregroundStyle(ColorToken.grayScale100.color)
            .accessibilityLabel(token.displayName)
        }

      Text(token.displayName)
        .font(TypographyToken.pretendardCaption1.font)
        .foregroundStyle(ColorToken.grayScale75.color)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.7)
    }
  }
}
