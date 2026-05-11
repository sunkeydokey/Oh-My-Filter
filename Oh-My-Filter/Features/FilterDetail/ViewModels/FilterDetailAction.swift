import Foundation

nonisolated enum FilterDetailAction: Equatable, Sendable {
  case task
  case retry
  case likeTapped
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
  case editCommentTapped(commentID: String)
  case editReplyTapped(parentCommentID: String, replyID: String)
  case cancelCommentEdit
  case deleteCommentTapped(commentID: String)
  case deleteReplyTapped(parentCommentID: String, replyID: String)
  case deleteCommentConfirmed
  case dismissDeleteCommentConfirmation
  case toggleReplies(commentID: String)
  case tapEdit
  case tapDelete
  case deleteConfirmed
  case dismissDeleteConfirmation
  case routeHandled
  case dismissHandled
  case dismissAlert
  case confirmAlert
}
