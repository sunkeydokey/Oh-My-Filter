import Foundation

nonisolated enum CommunityPostAction: Sendable {
  case task
  case retry
  case categoryChanged(String)
  case titleChanged(String)
  case contentChanged(String)
  case imageSelectionChanged([PhotoPickerUploadSelection])
  case removeExistingImage(String)
  case fieldFocused(CommunityPostField)
  case submit
  case cancelTapped
  case discardChangesConfirmed
  case likeTapped
  case editTapped
  case deleteTapped
  case deleteConfirmed
  case dismissDeleteConfirmation
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
  case routeHandled
  case dismissHandled
}

nonisolated enum CommunityPostField: Hashable, Sendable {
  case category
  case title
  case content
}
