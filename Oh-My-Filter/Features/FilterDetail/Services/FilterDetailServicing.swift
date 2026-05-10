import Foundation

nonisolated protocol FilterDetailServicing: Sendable {
  func loadFilterDetail(filterID: String) async throws -> FilterDetail
  func loadCurrentUserID() async throws -> String
  func deleteFilter(filterID: String) async throws
  func createComment(filterID: String, parentCommentID: String?, content: String) async throws -> CommentReply
  func updateComment(filterID: String, commentID: String, content: String) async throws -> CommentReply
  func deleteComment(filterID: String, commentID: String) async throws
}

nonisolated enum FilterDetailServiceError: Error, Equatable, LocalizedError, Sendable {
  case invalidResponse
  case serverError
  case transport

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      "필터 정보를 해석할 수 없습니다."
    case .serverError:
      "잠시 후 다시 시도해 주세요."
    case .transport:
      "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
    }
  }
}
