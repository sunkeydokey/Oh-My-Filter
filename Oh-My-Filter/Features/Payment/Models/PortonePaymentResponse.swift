import Foundation

nonisolated struct PortonePaymentResponse: Equatable, Sendable {
  let success: Bool
  let impUID: String?
  let merchantUID: String?
  let errorMessage: String?
  let errorCode: String?
}
