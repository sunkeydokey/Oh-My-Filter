import SwiftUI

private struct MulgyeolNavigationTitleModifier: ViewModifier {
  let title: String

  func body(content: Content) -> some View {
    content
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text(title)
            .font(TypographyToken.mulgyeolBody1.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .id("MulgyeolNavigationTitle-\(title)")
        }
      }
  }
}

extension View {
  func mulgyeolNavigationTitle(_ title: String) -> some View {
    modifier(MulgyeolNavigationTitleModifier(title: title))
  }
}
