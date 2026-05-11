import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CustomRootNavigationHeader: View {
  let title: String
  let trailingIcon: String?
  let trailingAction: (() -> Void)?

  init(
    title: String,
    trailingIcon: String? = nil,
    trailingAction: (() -> Void)? = nil
  ) {
    self.title = title
    self.trailingIcon = trailingIcon
    self.trailingAction = trailingAction
  }

  var body: some View {
    HStack {
      Text(title)
        .font(.custom(TypographyToken.mulgyeolTitle1.fontName, size: 24, relativeTo: .title2))
        .foregroundStyle(ColorToken.grayScale0.color)

      Spacer()

      if let icon = trailingIcon, let action = trailingAction {
        Button(action: action) {
          Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(ColorToken.grayScale0.color)
            .frame(width: 38, height: 38)
            .background(ColorToken.brandBlackSprout.color, in: Circle())
        }
        .buttonStyle(.plain)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct CustomStackNavigationHeader<Trailing: View>: View {
  let title: String
  let onBack: () -> Void
  @ViewBuilder let trailing: () -> Trailing

  var body: some View {
    HStack(spacing: 12) {
      Button(action: onBack) {
        Image(systemName: "chevron.left")
          .font(.system(size: 20, weight: .semibold))
          .frame(width: 44, height: 44)
      }
      .foregroundStyle(ColorToken.grayScale30.color)
      .buttonStyle(.plain)

      Spacer()

      Text(title)
        .font(.custom(TypographyToken.mulgyeolTitle1.fontName, size: 20, relativeTo: .headline))
        .foregroundStyle(ColorToken.grayScale30.color)

      Spacer()

      trailing()
        .frame(minWidth: 44)
    }
    .frame(height: 44)
  }
}

extension View {
  func swipeBackEnabled() -> some View {
    background(SwipeBackEnabler())
  }
}

#if canImport(UIKit)
private struct SwipeBackEnabler: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UIViewController {
    SwipeBackViewController()
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private final class SwipeBackViewController: UIViewController {
  override func didMove(toParent parent: UIViewController?) {
    super.didMove(toParent: parent)
    navigationController?.interactivePopGestureRecognizer?.delegate = nil
    navigationController?.interactivePopGestureRecognizer?.isEnabled = true
  }
}
#endif
