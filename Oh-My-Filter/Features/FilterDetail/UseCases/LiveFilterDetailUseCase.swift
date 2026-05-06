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

  func createComment(filterID: String, parentCommentID: String?, content: String) async throws -> CommentReply {
    try await service.createComment(filterID: filterID, parentCommentID: parentCommentID, content: content)
  }
}
