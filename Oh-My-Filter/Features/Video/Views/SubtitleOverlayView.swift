import SwiftUI

struct SubtitleOverlayView: View {
  let text: String

  var body: some View {
    Text(text)
      .font(TypographyToken.pretendardBody2.font)
      .multilineTextAlignment(.center)
      .lineSpacing(3)
      .foregroundStyle(ColorToken.grayScale30.color)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color.black.opacity(0.72))
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .frame(maxWidth: .infinity)
      .fixedSize(horizontal: false, vertical: true)
  }
}
