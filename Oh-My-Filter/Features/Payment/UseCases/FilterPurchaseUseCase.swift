import Foundation

nonisolated protocol FilterPurchaseUseCase: Sendable {
  func makePaymentRequest(for detail: FilterDetail) async throws -> PortonePaymentRequest
  func validatePaymentResponse(_ response: PortonePaymentResponse) async throws
}

nonisolated enum FilterPurchaseError: Error, Equatable, LocalizedError, Sendable {
  case alreadyPurchased
  case paymentFailed(String?)
  case missingApproval

  var errorDescription: String? {
    switch self {
    case .alreadyPurchased:
      "이미 구매한 필터입니다."
    case let .paymentFailed(message):
      message ?? "결제가 완료되지 않았습니다."
    case .missingApproval:
      "결제 승인 정보를 확인할 수 없습니다."
    }
  }
}

nonisolated struct LiveFilterPurchaseUseCase: FilterPurchaseUseCase {
  private let orderService: any OrderServicing
  private let paymentService: any PaymentServicing

  init(
    orderService: any OrderServicing,
    paymentService: any PaymentServicing
  ) {
    self.orderService = orderService
    self.paymentService = paymentService
  }

  @MainActor
  init() {
    self.init(
      orderService: LiveOrderService(),
      paymentService: LivePaymentService()
    )
  }

  func makePaymentRequest(for detail: FilterDetail) async throws -> PortonePaymentRequest {
    guard detail.isDownloaded == false else {
      throw FilterPurchaseError.alreadyPurchased
    }

    let order = try await orderService.createOrder(
      request: OrderCreateRequest(filterId: detail.id, totalPrice: detail.price)
    )
    return PortonePaymentRequest(detail: detail, merchantUID: order.orderCode)
  }

  func validatePaymentResponse(_ response: PortonePaymentResponse) async throws {
    guard response.success else {
      throw FilterPurchaseError.paymentFailed(response.errorMessage)
    }

    guard let impUID = response.impUID, impUID.isEmpty == false else {
      throw FilterPurchaseError.missingApproval
    }

    try await paymentService.validatePayment(
      request: PaymentValidationRequest(impUid: impUID)
    )
  }
}
