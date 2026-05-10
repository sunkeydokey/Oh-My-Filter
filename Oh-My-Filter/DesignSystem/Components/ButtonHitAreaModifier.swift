import SwiftUI

struct ButtonHitAreaModifier<S: Shape>: ViewModifier {
  let shape: S

  func body(content: Content) -> some View {
    content.contentShape(.interaction, shape)
  }
}

extension View {
  func buttonHitArea<S: Shape>(_ shape: S) -> some View {
    modifier(ButtonHitAreaModifier(shape: shape))
  }
}
