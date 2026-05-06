import Foundation

nonisolated protocol FilterDetailUseCase: Sendable {
  func loadFilterDetail(filterID: String) async throws -> FilterDetail
  func loadCurrentUserID() async throws -> String
  func createComment(filterID: String, parentCommentID: String?, content: String) async throws -> CommentReply
}
