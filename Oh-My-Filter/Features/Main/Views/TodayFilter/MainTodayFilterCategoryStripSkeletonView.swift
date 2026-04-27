import SwiftUI

struct MainTodayFilterCategoryStripSkeletonView: View {
  var body: some View {
    HStack(spacing: 0) {
      Spacer(minLength: 0)

      ForEach(MainTodayFilterCategoryItems.all) { _ in
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(ColorToken.grayScale75.color.opacity(0.45))
          .frame(width: 56, height: 56)

        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity)
  }
}
