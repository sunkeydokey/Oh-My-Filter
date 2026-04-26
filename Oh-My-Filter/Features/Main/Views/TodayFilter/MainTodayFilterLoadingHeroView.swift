import SwiftUI

struct MainTodayFilterLoadingHeroView: View {
  var body: some View {
    ZStack {
      MainTodayFilterHeroFallbackGradientView()

      VStack(alignment: .leading, spacing: 18) {
        HStack {
          Spacer(minLength: 0)

          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(ColorToken.grayScale75.color.opacity(0.45))
            .frame(width: 72, height: 28)
        }

        Spacer(minLength: MainTodayFilterLayout.contentTopOffset)

        VStack(alignment: .leading, spacing: 8) {
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(ColorToken.grayScale75.color.opacity(0.45))
            .frame(width: 124, height: 18)

          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(ColorToken.grayScale75.color.opacity(0.45))
            .frame(width: 240, height: 34)

          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(ColorToken.grayScale75.color.opacity(0.45))
            .frame(width: 302, height: 54)
        }

        Spacer(minLength: 0)

        MainTodayFilterCategoryStripSkeletonView()
      }
      .padding(.vertical, 20)
      .padding(.horizontal, MainViewLayout.contentHorizontalInset)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: .infinity, minHeight: MainTodayFilterLayout.heroHeight)
  }
}
