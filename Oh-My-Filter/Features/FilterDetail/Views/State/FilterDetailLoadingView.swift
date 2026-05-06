import SwiftUI

struct FilterDetailLoadingView: View {
  var body: some View {
    VStack(spacing: 16) {
      ProgressView()
        .tint(ColorToken.mainAccent.color)

      Text("필터를 불러오는 중입니다.")
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale45.color)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
  }
}
