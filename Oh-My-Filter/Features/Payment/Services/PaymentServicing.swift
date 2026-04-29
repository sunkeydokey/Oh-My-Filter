import Foundation

nonisolated protocol PaymentServicing: Sendable {
  func validatePayment(request: PaymentValidationRequest) async throws
}

nonisolated enum PaymentServiceError: Error, Equatable, LocalizedError, Sendable {
  case validationFailed
  case transport

  var errorDescription: String? {
    switch self {
    case .validationFailed:
      "결제 검증에 실패했습니다. 잠시 후 다시 시도해 주세요."
    case .transport:
      "네트워크 상태를 확인한 뒤 결제 상태를 다시 확인해 주세요."
    }
  }
}
