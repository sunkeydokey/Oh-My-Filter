import Foundation

nonisolated struct FeedState: Equatable, Sendable {
  var sort: FeedSort = .popularity
  var filters: [FeedFilter] = []
  var nextCursor: String?
  var isInitialLoading = false
  var isLoadingMore = false
  var hasLoaded = false
  var errorMessage: String?
  var paginationErrorMessage: String?

  var topRankingFilters: [FeedFilter] {
    Array(filters.prefix(5))
  }

  var canLoadMore: Bool {
    hasLoaded && isInitialLoading == false && isLoadingMore == false && nextCursor != nil && nextCursor != "0"
  }
}
