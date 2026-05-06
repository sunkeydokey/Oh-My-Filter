import SwiftUI

struct MainTodayFilterFailedHeroView: View {
  let message: String
  let retryAction: () -> Void

  var body: some View {
    ZStack {
      MainTodayFilterHeroFallbackGradientView()

      VStack(alignment: .leading, spacing: 20) {
        HStack {
          Spacer(minLength: 0)

          Text("사용해보기")
            .font(.custom(TypographyToken.pretendardBody3.fontName, size: 12, relativeTo: .caption))
            .foregroundStyle(ColorToken.grayScale60.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
              ColorToken.grayScale75.color.opacity(0.5),
              in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ColorToken.grayScale75.color.opacity(0.85), lineWidth: 1)
            )
        }

        Spacer(minLength: 188)

        VStack(alignment: .leading, spacing: 8) {
          Text("오늘의 필터를 불러오지 못했어요.")
            .font(TypographyToken.pretendardTitle1.font)
            .foregroundStyle(ColorToken.grayScale0.color)
            .fixedSize(horizontal: false, vertical: true)

          Text(message)
            .font(.custom(TypographyToken.pretendardBody3.fontName, size: 12, relativeTo: .subheadline))
            .foregroundStyle(ColorToken.grayScale45.color)
            .fixedSize(horizontal: false, vertical: true)
        }

        Button("다시 시도", action: retryAction)
          .buttonStyle(.borderedProminent)
          .tint(ColorToken.mainAccent.color)

        Spacer(minLength: 0)

        MainTodayFilterCategoryStripView()
      }
      .padding(.vertical, 20)
      .padding(.horizontal, MainViewLayout.contentHorizontalInset)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .frame(maxWidth: .infinity, minHeight: MainTodayFilterLayout.heroHeight)
  }
}
