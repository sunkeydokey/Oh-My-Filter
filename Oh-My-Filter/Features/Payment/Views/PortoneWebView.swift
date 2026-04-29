import SwiftUI
import UIKit
import WebKit
import iamport_ios

struct PortoneWebView: UIViewControllerRepresentable {
  let paymentRequest: PortonePaymentRequest
  let onResponse: @MainActor (PortonePaymentResponse?) -> Void

  func makeUIViewController(context: Context) -> PortoneViewController {
    PortoneViewController(paymentRequest: paymentRequest, onResponse: onResponse)
  }

  func updateUIViewController(_ uiViewController: PortoneViewController, context: Context) {}
}

final class PortoneViewController: UIViewController {
  private let paymentRequest: PortonePaymentRequest
  private let onResponse: @MainActor (PortonePaymentResponse?) -> Void
  private let webView = WKWebView(frame: .zero)
  private var didStartPayment = false

  init(
    paymentRequest: PortonePaymentRequest,
    onResponse: @escaping @MainActor (PortonePaymentResponse?) -> Void
  ) {
    self.paymentRequest = paymentRequest
    self.onResponse = onResponse
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    Iamport.shared.close()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(ColorToken.brandBlackSprout.color)
    configureWebView()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    startPaymentIfNeeded()
  }

  private func configureWebView() {
    webView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(webView)

    NSLayoutConstraint.activate([
      webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      webView.topAnchor.constraint(equalTo: view.topAnchor),
      webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func startPaymentIfNeeded() {
    guard didStartPayment == false else { return }

    didStartPayment = true
    Iamport.shared.paymentWebView(
      webViewMode: webView,
      userCode: SDK.Payment.userCode,
      payment: iamportPayment()
    ) { [weak self] response in
      guard let self else { return }
      Task { @MainActor in
        self.onResponse(response.map(PortonePaymentResponse.init(response:)))
      }
    }
  }

  private func iamportPayment() -> IamportPayment {
    let payment = IamportPayment(
      pg: paymentRequest.pgCode,
      merchant_uid: paymentRequest.merchantUID,
      amount: paymentRequest.amount
    )
    payment.pay_method = paymentRequest.payMethod
    payment.name = paymentRequest.name
    payment.buyer_name = paymentRequest.buyerName
    payment.app_scheme = paymentRequest.appScheme
    return payment
  }
}

private extension PortonePaymentResponse {
  init(response: IamportResponse) {
    self.init(
      success: response.success ?? false,
      impUID: response.imp_uid,
      merchantUID: response.merchant_uid,
      errorMessage: response.error_msg,
      errorCode: response.error_code
    )
  }
}
