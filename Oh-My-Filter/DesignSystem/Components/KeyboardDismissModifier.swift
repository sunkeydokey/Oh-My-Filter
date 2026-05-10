import SwiftUI
import UIKit

private struct KeyboardDismissModifier: ViewModifier {
  func body(content: Content) -> some View {
    content.background(KeyboardDismissGestureInstaller())
  }
}

extension View {
  func keyboardDismissOnTap() -> some View {
    modifier(KeyboardDismissModifier())
  }
}

private struct KeyboardDismissGestureInstaller: UIViewRepresentable {
  func makeUIView(context: Context) -> KeyboardDismissInstallerView {
    KeyboardDismissInstallerView(coordinator: context.coordinator)
  }

  func updateUIView(_ uiView: KeyboardDismissInstallerView, context: Context) {
    uiView.coordinator = context.coordinator
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  final class Coordinator: NSObject, UIGestureRecognizerDelegate {
    private weak var window: UIWindow?
    private var recognizer: UITapGestureRecognizer?

    func install(on window: UIWindow?) {
      guard self.window !== window else { return }

      if let recognizer {
        self.window?.removeGestureRecognizer(recognizer)
      }

      self.window = window

      guard let window else {
        recognizer = nil
        return
      }

      let recognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(dismissKeyboard)
      )
      recognizer.cancelsTouchesInView = false
      recognizer.delegate = self
      window.addGestureRecognizer(recognizer)
      self.recognizer = recognizer
    }

    @objc func dismissKeyboard(_ recognizer: UITapGestureRecognizer) {
      window?.endEditing(true)
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldReceive touch: UITouch
    ) -> Bool {
      var view = touch.view

      while let currentView = view {
        if currentView is UIControl || currentView is UITextView {
          return false
        }

        view = currentView.superview
      }

      return true
    }

    func gestureRecognizer(
      _ gestureRecognizer: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
      true
    }
  }
}

private final class KeyboardDismissInstallerView: UIView {
  weak var coordinator: KeyboardDismissGestureInstaller.Coordinator? {
    didSet {
      coordinator?.install(on: window)
    }
  }

  init(coordinator: KeyboardDismissGestureInstaller.Coordinator) {
    self.coordinator = coordinator
    super.init(frame: .zero)
    backgroundColor = .clear
    isUserInteractionEnabled = false
  }

  required init?(coder: NSCoder) {
    nil
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    coordinator?.install(on: window)
  }
}
