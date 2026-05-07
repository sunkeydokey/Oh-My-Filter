import SwiftUI
import UIKit

extension View {
  func screenCaptureProtected(_ isProtected: Bool) -> some View {
    self.modifier(ScreenCaptureProtectedModifier(isProtected: isProtected))
  }
}

private struct ScreenCaptureProtectedModifier: ViewModifier {
  let isProtected: Bool
  @State private var isCapturing = false

  func body(content: Content) -> some View {
    content
      .overlay {
        if isProtected && isCapturing {
          Color.black.ignoresSafeArea()
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
        guard isProtected else { return }
        isCapturing = UIScreen.main.isCaptured
      }
      .onAppear {
        guard isProtected else { return }
        isCapturing = UIScreen.main.isCaptured
      }
  }
}
