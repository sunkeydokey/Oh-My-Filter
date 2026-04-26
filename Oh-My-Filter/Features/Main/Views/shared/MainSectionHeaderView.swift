import SwiftUI

struct MainSectionHeaderView: View {
  let title: String
  let subtitle: String?

  init(title: String, subtitle: String? = nil) {
    self.title = title
    self.subtitle = subtitle
  }

  var body: some View {
    VStack(alignment: .leading, spacing: subtitle == nil ? 0 : 6) {
      Text(title)
        .font(TypographyToken.pretendardTitle1.font)
        .foregroundStyle(ColorToken.grayScale0.color)

      if let subtitle {
        Text(subtitle)
          .font(TypographyToken.pretendardBody3.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}
