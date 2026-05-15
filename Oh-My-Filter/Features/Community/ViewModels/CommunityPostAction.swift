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
  case localSaveSucceededHandled
  case detailSavePhaseHandled
  case errorPresented(String)
  case errorDismissed

  // Create/Edit: 이미지 타일 액션
  case saveLocalImageTapped(selectionID: UUID)
  case convertLocalImageToAnimeTapped(selectionID: UUID)

  // AnimeGAN 내부 진행 (Create/Edit)
  case animeConversionProduced(selectionID: UUID, result: AnimeConversionResult)
  case animeConversionFailed(selectionID: UUID, message: String)
  case animeConversionChoiceMade(useConverted: Bool)
  case animeConversionDismissed

  // Detail: 캐러셀 이미지 저장 흐름
  case saveRemoteImageTapped(url: URL)
  case convertRemoteImageToAnimeTapped(url: URL)
  case animeConversionForSaveProduced(result: AnimeConversionResult)
  case saveAnimeResult
}

nonisolated enum CommunityPostField: Hashable, Sendable {
  case category
  case title
  case content
}
