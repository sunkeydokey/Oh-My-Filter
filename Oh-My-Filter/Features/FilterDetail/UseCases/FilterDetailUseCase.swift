import Foundation

nonisolated protocol FilterDetailUseCase: Sendable {
  func loadFilterDetail(filterID: String) async throws -> FilterDetail
  func loadCurrentUserID() async throws -> String
  func deleteFilter(filterID: String) async throws
  func createComment(filterID: String, parentCommentID: String?, content: String) async throws -> CommentReply
  func updateComment(filterID: String, commentID: String, content: String) async throws -> CommentReply
  func deleteComment(filterID: String, commentID: String) async throws
}
