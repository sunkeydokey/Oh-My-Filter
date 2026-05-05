import SwiftUI
import UIKit
import WebKit

struct BannerWebView: UIViewControllerRepresentable {
  let url: URL
  let onComplete: @MainActor (Int) -> Void
  let onDismiss: @MainActor () -> Void

  func makeUIViewController(context: Context) -> BannerWebViewController {
    BannerWebViewController(url: url, onComplete: onComplete, onDismiss: onDismiss)
  }

  func updateUIViewController(_ uiViewController: BannerWebViewController, context: Context) {}
}

final class BannerWebViewController: UIViewController {
  private let url: URL
  private let onComplete: @MainActor (Int) -> Void
  private let onDismiss: @MainActor () -> Void

  private var webView: WKWebView!
  private let contentController = WKUserContentController()

  init(
    url: URL,
    onComplete: @escaping @MainActor (Int) -> Void,
    onDismiss: @escaping @MainActor () -> Void
  ) {
    self.url = url
    self.onComplete = onComplete
    self.onDismiss = onDismiss
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError() }

  override func viewDidLoad() {
    super.viewDidLoad()

    contentController.add(self, name: "click_attendance_button")
    contentController.add(self, name: "complete_attendance")

    let config = WKWebViewConfiguration()
    config.userContentController = contentController

    webView = WKWebView(frame: .zero, configuration: config)
    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let dismissButton = UIButton(type: .system)
    let image = UIImage(systemName: "xmark")
    dismissButton.setImage(image, for: .normal)
    dismissButton.tintColor = .white
    dismissButton.translatesAutoresizingMaskIntoConstraints = false
    dismissButton.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    view.addSubview(dismissButton)
    NSLayoutConstraint.activate([
      dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      dismissButton.widthAnchor.constraint(equalToConstant: 44),
      dismissButton.heightAnchor.constraint(equalToConstant: 44),
    ])

    var request = URLRequest(url: url)
    request.setValue(Server.apiKey(), forHTTPHeaderField: "SeSACKey")
    webView.load(request)
  }

  deinit {
    contentController.removeScriptMessageHandler(forName: "click_attendance_button")
    contentController.removeScriptMessageHandler(forName: "complete_attendance")
  }

  @objc private func dismissTapped() {
    Task { @MainActor in onDismiss() }
  }
}

extension BannerWebViewController: WKScriptMessageHandler {
  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    switch message.name {
    case "click_attendance_button":
      Task { @MainActor in
        let token = try await AppTokenRefreshCoordinator.shared.authorizationHeaderValue()
        try await webView.evaluateJavaScript("requestAttendance('\(token)')")
      }
    case "complete_attendance":
      let count = message.body as? Int ?? 0
      Task { @MainActor in onComplete(count) }
    default:
      break
    }
  }
}
