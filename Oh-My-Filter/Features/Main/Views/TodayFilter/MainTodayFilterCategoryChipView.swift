import SwiftUI

struct MainTodayFilterCategoryChipView: View {
  let item: MainTodayFilterCategoryItem

  var body: some View {
    VStack(spacing: 6) {
      RoundedRectangle(cornerRadius: 10, style: .continuous)
        .fill(ColorToken.grayScale75.color.opacity(0.5))
        .frame(width: 56, height: 56)
        .overlay {
          Image(systemName: item.systemImage)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(ColorToken.brandBlackSprout.color)
        }
        .overlay(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(ColorToken.grayScale75.color.opacity(0.6), lineWidth: 1)
        )

      Text(item.title)
        .font(.custom(TypographyToken.pretendardCaption2.fontName, size: 10, relativeTo: .caption2))
        .foregroundStyle(ColorToken.grayScale60.color)
        .lineLimit(1)
    }
    .frame(width: 56)
  }
}
