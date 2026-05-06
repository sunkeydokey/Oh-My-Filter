import Foundation

nonisolated struct CommentUser: Equatable, Sendable {
  let id: String
  let nick: String
  let name: String?
  let profileImageURL: URL?
  let introduction: String?
  let hashTags: [String]

  var displayName: String {
    name ?? nick
  }
}

nonisolated struct Comment: Equatable, Identifiable, Sendable {
  let id: String
  let content: String
  let createdAt: String
  let creator: CommentUser
  let replies: [CommentReply]
}

nonisolated struct CommentReply: Equatable, Identifiable, Sendable {
  let id: String
  let content: String
  let createdAt: String
  let creator: CommentUser
}

