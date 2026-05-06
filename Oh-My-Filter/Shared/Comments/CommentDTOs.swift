import Foundation

nonisolated struct CommentDTO: Decodable, Sendable {
  let commentId: String
  let content: String
  let createdAt: String
  let creator: CommentUserDTO
  let replies: [CommentReplyDTO]

  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    commentId = try container.decodeFlexibleString(forKey: .commentId) ?? UUID().uuidString
    content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
    createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
    creator = try container.decodeIfPresent(CommentUserDTO.self, forKey: .creator)
      ?? (try container.decodeIfPresent(CommentUserDTO.self, forKey: .user))
      ?? .unknown
    replies = (try? container.decode([CommentReplyDTO].self, forKey: .replies)) ?? []
  }

  private enum CodingKeys: String, CodingKey {
    case commentId
    case content
    case createdAt
    case creator
    case user
    case replies
  }
}

nonisolated struct CommentReplyDTO: Decodable, Sendable {
  let commentId: String
  let content: String
  let createdAt: String
  let creator: CommentUserDTO

  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    commentId = try container.decodeFlexibleString(forKey: .commentId)
      ?? container.decodeFlexibleString(forKey: .replyId)
      ?? UUID().uuidString
    content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
    createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
    creator = try container.decodeIfPresent(CommentUserDTO.self, forKey: .creator)
      ?? (try container.decodeIfPresent(CommentUserDTO.self, forKey: .user))
      ?? .unknown
  }

  private enum CodingKeys: String, CodingKey {
    case commentId
    case replyId
    case content
    case createdAt
    case creator
    case user
  }
}

nonisolated struct CommentUserDTO: Decodable, Sendable {
  let userId: String
  let nick: String
  let name: String?
  let introduction: String?
  let profileImage: String?
  let hashTags: [String]?

  static let unknown = CommentUserDTO(
    userId: "",
    nick: "알 수 없음",
    name: nil,
    introduction: nil,
    profileImage: nil,
    hashTags: []
  )
}

nonisolated struct CommentRequestDTO: Encodable, Sendable {
  let parent_comment_id: String?
  let content: String
}

extension CommentDTO {
  nonisolated func toDomain() -> Comment {
    Comment(
      id: commentId,
      content: content,
      createdAt: createdAt,
      creator: creator.toDomain(),
      replies: replies.map { $0.toDomain() }
    )
  }
}

extension CommentReplyDTO {
  nonisolated func toDomain() -> CommentReply {
    CommentReply(
      id: commentId,
      content: content,
      createdAt: createdAt,
      creator: creator.toDomain()
    )
  }
}

extension CommentUserDTO {
  nonisolated func toDomain() -> CommentUser {
    CommentUser(
      id: userId,
      nick: nick,
      name: name,
      profileImageURL: AuthenticatedRemoteImageSupport.url(from: profileImage),
      introduction: introduction,
      hashTags: hashTags ?? []
    )
  }
}

private extension KeyedDecodingContainer {
  nonisolated func decodeFlexibleString(forKey key: Key) throws -> String? {
    if let value = try decodeIfPresent(String.self, forKey: key) {
      return value
    }

    if let value = try decodeIfPresent(Int.self, forKey: key) {
      return String(value)
    }

    return nil
  }
}
