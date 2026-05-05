import Foundation

nonisolated enum MainSectionState<Value: Equatable & Sendable>: Equatable, Sendable {
  case idle
  case loading(previous: Value?)
  case loaded(Value)
  case failed(message: String, previous: Value?)

  var failureMessage: String? {
    guard case let .failed(message, _) = self else { return nil }
    return message
  }

  var value: Value? {
    switch self {
    case .idle:
      nil
    case let .loading(previous):
      previous
    case let .loaded(value):
      value
    case let .failed(_, previous):
      previous
    }
  }
}

nonisolated struct MainTodayFilter: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let subtitle: String?
  let description: String
  let imageUrl: URL?
  let creatorName: String?
  let creatorProfileImageUrl: URL?
}

nonisolated struct MainBanner: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let subtitle: String
  let imageUrl: URL?
  let webViewURL: URL?
}

nonisolated struct MainHotTrendFilter: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let imageUrl: URL?
  let creatorName: String?
  let creatorProfileImageUrl: URL?
}

nonisolated struct MainTodayAuthor: Equatable, Identifiable, Sendable {
  let userID: String
  let nick: String
  let name: String
  let profileImageUrl: URL?
  let introduction: String?
  let description: String?
  let hashTags: [String]
  let filters: [MainTodayAuthorFilter]

  var id: String { userID }
}

nonisolated struct MainTodayAuthorFilter: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let category: String?
  let description: String
  let imageUrl: URL?
}
