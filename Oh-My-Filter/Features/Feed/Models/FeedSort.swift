import Foundation

nonisolated enum FeedSort: String, CaseIterable, Sendable {
  case popularity
  case purchase
  case latest

  var title: String {
    switch self {
    case .popularity:
      "인기순"
    case .purchase:
      "구매순"
    case .latest:
      "최신순"
    }
  }
}
