import SwiftUI

struct DesignSystemCatalogView: View {
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text("Oh My Filter Asset Tokens")
            .font(TypographyToken.pretendardTitle1.font)
            .foregroundStyle(ColorToken.brandBlackSprout.color)

          Text("피그마 애셋 프로젝트의 컬러, 타이포그래피, 아이콘 토큰을 한 화면에서 확인할 수 있습니다.")
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale75.color)

          ColorTokenSectionView()
          TypographyTokenSectionView()
          IconTokenSectionView()
        }
        .padding(24)
      }
      .background(ColorToken.grayScale15.color)
      .navigationTitle("Design System")
    }
  }
}

#Preview {
  DesignSystemCatalogView()
}
