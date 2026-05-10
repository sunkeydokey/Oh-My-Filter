import Foundation

nonisolated struct LiveFilterDetailUseCase: FilterDetailUseCase {
  private let service: any FilterDetailServicing

  init(service: any FilterDetailServicing) {
    self.service = service
  }

  @MainActor
  init() {
    self.init(service: LiveFilterDetailService())
  }

  func loadFilterDetail(filterID: String) async throws -> FilterDetail {
    try await service.loadFilterDetail(filterID: filterID)
  }

  func loadCurrentUserID() async throws -> String {
    try await service.loadCurrentUserID()
  }

  func deleteFilter(filterID: String) async throws {
    try await service.deleteFilter(filterID: filterID)
  }

  func createComment(filterID: String, parentCommentID: String?, content: String) async throws -> CommentReply {
    try await service.createComment(filterID: filterID, parentCommentID: parentCommentID, content: content)
  }

  func updateComment(filterID: String, commentID: String, content: String) async throws -> CommentReply {
    try await service.updateComment(filterID: filterID, commentID: commentID, content: content)
  }

  func deleteComment(filterID: String, commentID: String) async throws {
    try await service.deleteComment(filterID: filterID, commentID: commentID)
  }
}
