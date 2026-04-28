import Foundation

nonisolated protocol FilterDetailUseCase: Sendable {
  func loadFilterDetail(filterID: String) async throws -> FilterDetail
}
