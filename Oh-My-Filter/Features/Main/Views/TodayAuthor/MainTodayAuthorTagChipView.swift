import SwiftUI

struct MainTodayAuthorTagChipView: View {
  let title: String

  var body: some View {
    Text(title.hasPrefix("#") ? title : "#\(title)")
      .font(.custom(TypographyToken.pretendardCaption1.fontName, size: 12, relativeTo: .caption))
      .foregroundStyle(ColorToken.grayScale60.color)
      .padding(.horizontal, 12)
      .padding(.vertical, 5)
      .background(ColorToken.brandDeepSprout.color, in: Capsule())
      .overlay(
        Capsule()
        .stroke(ColorToken.grayScale90.color.opacity(0.65), lineWidth: 1)
      )
  }
}
