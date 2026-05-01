import Foundation

nonisolated struct FeedFilter: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let description: String
  let category: String?
  let imageURL: URL?
  let creatorNick: String?
  let likeCount: Int
  let buyerCount: Int
  let createdAt: String
}

nonisolated struct FeedPage: Equatable, Sendable {
  let filters: [FeedFilter]
  let nextCursor: String
}
