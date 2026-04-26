import SwiftUI

struct MainTodayAuthorLoadingCardView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(ColorToken.grayScale75.color.opacity(0.4))
        .frame(width: 160, height: 14)

      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .fill(ColorToken.grayScale75.color.opacity(0.4))
        .frame(width: 280, height: 42)

      HStack(alignment: .center, spacing: 16) {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
          .fill(ColorToken.grayScale75.color.opacity(0.4))
          .frame(width: 72, height: 72)

        VStack(alignment: .leading, spacing: 8) {
          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(ColorToken.grayScale75.color.opacity(0.4))
            .frame(width: 96, height: 18)

          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(ColorToken.grayScale75.color.opacity(0.4))
            .frame(width: 72, height: 14)
        }

        Spacer(minLength: 0)
      }

      HStack(spacing: 12) {
        MainTodayAuthorThumbnailSkeletonView()
        MainTodayAuthorThumbnailSkeletonView()
        MainTodayAuthorThumbnailSkeletonView()
      }
      .frame(maxWidth: .infinity)

      HStack(spacing: 8) {
        MainTodayAuthorTagSkeletonView()
        MainTodayAuthorTagSkeletonView()
        MainTodayAuthorTagSkeletonView()
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ColorToken.brandDeepSprout.color)
    .clipShape(.rect(cornerRadius: 24))
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    )
  }
}
