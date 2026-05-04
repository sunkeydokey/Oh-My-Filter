import SwiftUI

struct FilterPanelView<Content: View>: View {
  let title: String
  let trailing: String
  let content: Content

  init(
    title: String,
    trailing: String,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.trailing = trailing
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(title)
        Spacer()
        Text(trailing)
      }
      .font(TypographyToken.pretendardCaption1.font)
      .bold()
      .foregroundStyle(ColorToken.brandDeepSprout.color)
      .padding(.horizontal, 12)
      .padding(.vertical, 7)
      .background(ColorToken.grayScale45.color)

      content
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorToken.brandDeepSprout.color)
    }
    .clipShape(.rect(cornerRadius: 8))
  }
}
