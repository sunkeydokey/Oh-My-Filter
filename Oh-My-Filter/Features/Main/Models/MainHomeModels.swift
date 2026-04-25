import Foundation

enum MainSectionLoadState: Equatable, Sendable {
  case idle
  case loading
  case loaded
  case failed(message: String)

  var failureMessage: String? {
    guard case let .failed(message) = self else { return nil }
    return message
  }
}

struct MainTodayFilter: Equatable, Sendable {
  let id: String
  let title: String
  let subtitle: String
  let imageUrl: URL?
  let creatorName: String?
  let creatorProfileImageUrl: URL?
}

struct MainBanner: Equatable, Sendable {
  let id: String
  let title: String
  let subtitle: String
  let imageUrl: URL?
}

struct MainHotTrendFilter: Equatable, Sendable {
  let id: String
  let title: String
  let imageUrl: URL?
  let creatorName: String?
  let creatorProfileImageUrl: URL?
}

struct MainTodayAuthor: Equatable, Sendable {
  let userID: String
  let nick: String
  let profileImageUrl: URL?
  let introduction: String?
}
