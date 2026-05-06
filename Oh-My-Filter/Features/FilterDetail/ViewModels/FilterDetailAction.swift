import Foundation

nonisolated enum FilterDetailAction: Equatable, Sendable {
  case task
  case retry
  case tapDownload
  case paymentResponseReceived(PortonePaymentResponse?)
  case dismissPaymentSheet
  case commentTextChanged(String)
  case submitComment
  case replyTapped(commentID: String)
  case cancelReply
  case toggleReplies(commentID: String)
  case dismissAlert
  case confirmAlert
}
