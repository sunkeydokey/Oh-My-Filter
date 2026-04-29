import Foundation

nonisolated enum FilterDetailAction: Equatable, Sendable {
  case task
  case retry
  case tapDownload
  case paymentResponseReceived(PortonePaymentResponse?)
  case dismissPaymentSheet
  case dismissAlert
  case confirmAlert
}
