import Foundation

nonisolated protocol FeedListUseCase: Sendable {
  func loadFilters(nextCursor: String?, limit: Int, category: String?, sort: FeedSort) async throws -> FeedPage
}
