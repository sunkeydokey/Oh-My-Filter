import Foundation

nonisolated struct LivePaymentValidationUseCase: PaymentValidationUseCase {
  private let service: any PaymentServicing

  init(service: any PaymentServicing) {
    self.service = service
  }

  @MainActor
  init() {
    self.init(service: LivePaymentService())
  }

  func validatePayment(impUID: String) async throws {
    try await service.validatePayment(
      request: PaymentValidationRequest(impUid: impUID)
    )
  }
}
