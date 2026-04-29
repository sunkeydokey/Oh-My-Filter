import Foundation

nonisolated protocol PaymentValidationUseCase: Sendable {
  func validatePayment(impUID: String) async throws
}
