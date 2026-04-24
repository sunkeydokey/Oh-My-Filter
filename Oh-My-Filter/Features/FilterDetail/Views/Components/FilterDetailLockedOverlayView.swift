import SwiftUI

struct FilterDetailLockedOverlayView: View {
  var body: some View {
    ZStack {
      Rectangle()
        .fill(.ultraThinMaterial)

      ColorToken.grayScale90.color.opacity(0.72)

      VStack(spacing: 12) {
        Image(systemName: IconToken.secure.symbolName)
          .font(.title2)
          .foregroundStyle(ColorToken.grayScale0.color)

        Text("결제가 필요한 유료 필터입니다")
          .font(TypographyToken.pretendardBody2.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale0.color)
          .multilineTextAlignment(.center)
      }
      .padding()
    }
  }
}
