import SwiftUI

struct MainSectionHeaderView: View {
  let title: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(TypographyToken.pretendardTitle1.font)
        .foregroundStyle(ColorToken.grayScale0.color)

      Text(subtitle)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale60.color)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
