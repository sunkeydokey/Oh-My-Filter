import Foundation

nonisolated struct ChatUser: Equatable, Identifiable, Sendable {
  let id: String
  let nick: String
  let name: String?
  let introduction: String?
  let profileImage: String?
  let hashTags: [String]
}

nonisolated struct ChatMessage: Equatable, Identifiable, Sendable {
  let id: String
  let roomID: String
  let content: String
  let createdAt: Date
  let updatedAt: Date
  let sender: ChatUser
  let files: [String]
}

nonisolated struct ChatRoom: Equatable, Identifiable, Sendable {
  let id: String
  let updatedAt: Date
  let participants: [ChatUser]
  let lastMessage: ChatMessage?
  let lastSeenAt: Date?

  var isUnread: Bool {
    guard let lastSeenAt else { return lastMessage != nil }
    return updatedAt > lastSeenAt
  }
}

nonisolated enum ChatDateParser {
  static func date(from value: String) throws -> Date {
    do {
      return try Date(value, strategy: .iso8601)
    } catch {
      let strategy = Date.ISO8601FormatStyle(includingFractionalSeconds: false)
      return try Date(value, strategy: strategy)
    }
  }
}

extension ChatUserInfoResponseDTO {
  var domain: ChatUser {
    ChatUser(
      id: userId,
      nick: nick,
      name: name,
      introduction: introduction,
      profileImage: profileImage,
      hashTags: hashTags
    )
  }
}

extension ChatResponseDTO {
  func domain() throws -> ChatMessage {
    ChatMessage(
      id: chatId,
      roomID: roomId,
      content: content,
      createdAt: try ChatDateParser.date(from: createdAt),
      updatedAt: try ChatDateParser.date(from: updatedAt),
      sender: sender.domain,
      files: files
    )
  }
}

extension ChatRoomResponseDTO {
  func domain(lastSeenAt: Date?) throws -> ChatRoom {
    ChatRoom(
      id: roomId,
      updatedAt: try ChatDateParser.date(from: updatedAt),
      participants: participants.map(\.domain),
      lastMessage: try lastChat?.domain(),
      lastSeenAt: lastSeenAt
    )
  }
}
