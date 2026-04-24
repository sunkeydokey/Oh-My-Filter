import SwiftUI

struct AuthCard<Content: View>: View {
  @ViewBuilder private let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      content
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ColorToken.brandBlackSprout.color)
    .clipShape(.rect(cornerRadius: CornerRadiusToken.section.value))
  }
}
