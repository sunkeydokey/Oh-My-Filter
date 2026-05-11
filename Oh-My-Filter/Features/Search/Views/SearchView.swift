import SwiftUI

struct SearchView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      CustomRootNavigationHeader(title: "SEARCH")
        .padding(.horizontal, 20)
        .padding(.top, 18)

      VStack(spacing: 12) {
        Image(systemName: IconToken.search.symbolName)
          .font(.system(size: 28, weight: .semibold))

        Text("검색")
          .font(TypographyToken.pretendardBody1.font)
          .bold()
      }
      .foregroundStyle(ColorToken.grayScale45.color)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
  }
}
