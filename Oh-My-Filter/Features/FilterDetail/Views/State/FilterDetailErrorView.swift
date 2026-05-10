import SwiftUI

struct FilterDetailErrorView: View {
  let message: String
  let retryAction: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: IconToken.warning.symbolName)
        .font(.largeTitle)
        .foregroundStyle(ColorToken.grayScale60.color)

      Text(message)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale45.color)

      Button(action: retryAction) {
        Text("다시 시도")
          .font(TypographyToken.pretendardBody2.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale0.color)
          .padding(.horizontal, 18)
          .padding(.vertical, 10)
          .background(ColorToken.sesacFilterDeepTurquoise.color, in: Capsule())
          .buttonHitArea(Capsule())
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
  }
}
