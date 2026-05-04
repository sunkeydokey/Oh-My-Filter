import SwiftUI

struct ProfileView: View {
  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: IconToken.profile.symbolName)
        .font(.system(size: 28, weight: .semibold))

      Text("프로필")
        .font(TypographyToken.pretendardBody1.font)
        .bold()
    }
    .foregroundStyle(ColorToken.grayScale45.color)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
    .mulgyeolNavigationTitle("PROFILE")
  }
}
