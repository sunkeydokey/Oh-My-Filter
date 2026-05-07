import Foundation

nonisolated enum FilterDetailAction: Equatable, Sendable {
  case task
  case retry
  case tapDownload
  case tapApply
  case tapPurchaseRequired
  case photosSelected([Data])
  case saveCurrentFilteredImage
  case saveAllFilteredImages
  case previewIndexChanged(Int)
  case dismissApplySheet
  case paymentResponseReceived(PortonePaymentResponse?)
  case dismissPaymentSheet
  case commentTextChanged(String)
  case submitComment
  case replyTapped(commentID: String)
  case cancelReply
  case toggleReplies(commentID: String)
  case tapEdit
  case routeHandled
  case dismissAlert
  case confirmAlert
}
