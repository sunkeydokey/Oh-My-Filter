import Foundation

nonisolated protocol FilterDetailUseCase: Sendable {
  func loadFilterDetail(filterID: String) async throws -> FilterDetail
  func createComment(filterID: String, parentCommentID: String?, content: String) async throws -> CommentReply
}
