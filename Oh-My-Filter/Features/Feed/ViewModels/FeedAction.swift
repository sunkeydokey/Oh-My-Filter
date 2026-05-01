import Foundation

nonisolated enum FeedAction: Equatable, Sendable {
  case task
  case sortChanged(FeedSort)
  case loadMoreIfNeeded(FeedFilter)
  case retry
}
