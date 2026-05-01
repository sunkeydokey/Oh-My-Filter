import Foundation

nonisolated struct LiveFeedListUseCase: FeedListUseCase {
  private let service: any FeedServicing

  init(service: any FeedServicing) {
    self.service = service
  }

  @MainActor
  init() {
    self.init(service: LiveFeedService())
  }

  func loadFilters(
    nextCursor: String?,
    limit: Int,
    category: String?,
    sort: FeedSort
  ) async throws -> FeedPage {
    try await service.loadFilters(nextCursor: nextCursor, limit: limit, category: category, sort: sort)
  }
}
