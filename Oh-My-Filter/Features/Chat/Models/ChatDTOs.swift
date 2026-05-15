import Foundation

nonisolated struct ChatRoomCreateRequestDTO: Encodable, Equatable, Sendable {
  let opponentId: String

  enum CodingKeys: String, CodingKey {
    case opponentId = "opponent_id"
  }
}

nonisolated struct ChatSendRequestDTO: Encodable, Equatable, Sendable {
  let content: String
  let files: [String]?

  init(content: String, files: [String]? = nil) {
    self.content = content
    self.files = files
  }
}

nonisolated struct ChatRoomListResponseDTO: Decodable, Equatable, Sendable {
  let data: [ChatRoomResponseDTO]
}

nonisolated struct ChatRoomResponseDTO: Decodable, Equatable, Sendable {
  let roomId: String
  let createdAt: String
  let updatedAt: String
  let participants: [ChatUserInfoResponseDTO]
  let lastChat: ChatResponseDTO?
}

nonisolated struct ChatListResponseDTO: Decodable, Equatable, Sendable {
  let data: [ChatResponseDTO]
}

nonisolated struct ChatUserSearchResponseDTO: Decodable, Equatable, Sendable {
  let data: [ChatUserInfoResponseDTO]
}

nonisolated struct ChatResponseDTO: Decodable, Equatable, Sendable {
  let chatId: String
  let roomId: String
  let content: String
  let createdAt: String
  let updatedAt: String
  let sender: ChatUserInfoResponseDTO
  let files: [String]

  enum CodingKeys: String, CodingKey {
    case chatId
    case roomId
    case content
    case createdAt
    case updatedAt
    case sender
    case files
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    chatId = try container.decode(String.self, forKey: .chatId)
    roomId = try container.decode(String.self, forKey: .roomId)
    content = try container.decode(String.self, forKey: .content)
    createdAt = try container.decode(String.self, forKey: .createdAt)
    updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? createdAt
    sender = try container.decode(ChatUserInfoResponseDTO.self, forKey: .sender)
    files = try container.decodeIfPresent([String].self, forKey: .files) ?? []
  }
}

nonisolated struct ChatUserInfoResponseDTO: Decodable, Equatable, Sendable {
  let userId: String
  let nick: String
  let name: String?
  let introduction: String?
  let profileImage: String?
  let hashTags: [String]

  enum CodingKeys: String, CodingKey {
    case userId
    case nick
    case name
    case introduction
    case profileImage
    case hashTags
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    userId = try container.decode(String.self, forKey: .userId)
    nick = try container.decode(String.self, forKey: .nick)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    introduction = try container.decodeIfPresent(String.self, forKey: .introduction)
    profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
    hashTags = try container.decodeIfPresent([String].self, forKey: .hashTags) ?? []
  }
}
