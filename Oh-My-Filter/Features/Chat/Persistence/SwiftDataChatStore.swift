import Foundation
import SwiftData

@MainActor
final class SwiftDataChatStore: ChatLocalStoring {
  private let context: ModelContext
  private let retainedContainer: ModelContainer?

  init(context: ModelContext) {
    self.context = context
    retainedContainer = nil
  }

  init(container: ModelContainer) {
    context = container.mainContext
    retainedContainer = container
  }

  func fetchRooms() throws -> [ChatRoom] {
    var descriptor = FetchDescriptor<ChatRoomRecord>(
      sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
    )
    descriptor.includePendingChanges = true

    return try context.fetch(descriptor).map { record in
      let messages = try fetchMessages(roomID: record.roomID)
      return ChatRoom(
        id: record.roomID,
        updatedAt: record.updatedAt,
        participants: users(from: record.participantSummary),
        lastMessage: messages.last,
        lastSeenAt: record.lastLocalSeenAt
      )
    }
  }

  func fetchMessages(roomID: String) throws -> [ChatMessage] {
    let descriptor = FetchDescriptor<ChatMessageRecord>(
      sortBy: [SortDescriptor(\.createdAt)]
    )
    return try context.fetch(descriptor)
      .filter { $0.roomID == roomID }
      .map(\.domain)
  }

  func newestMessageDate(roomID: String) throws -> Date? {
    try fetchMessages(roomID: roomID).last?.createdAt
  }

  func lastSeenAt(roomID: String) throws -> Date? {
    try roomRecord(roomID: roomID)?.lastLocalSeenAt
  }

  func upsertRoom(_ room: ChatRoom) throws {
    if let record = try roomRecord(roomID: room.id) {
      record.updatedAt = room.updatedAt
      record.participantSummary = participantSummary(from: room.participants)
      if let lastSeenAt = room.lastSeenAt {
        record.lastLocalSeenAt = lastSeenAt
      }
    } else {
      context.insert(
        ChatRoomRecord(
          roomID: room.id,
          updatedAt: room.updatedAt,
          participantSummary: participantSummary(from: room.participants),
          lastLocalSeenAt: room.lastSeenAt
        )
      )
    }

    if let lastMessage = room.lastMessage {
      try upsertMessage(lastMessage)
    }
    try context.save()
  }

  func upsertRooms(_ rooms: [ChatRoom]) throws {
    for room in rooms {
      try upsertRoom(room)
    }
  }

  func upsertMessage(_ message: ChatMessage) throws {
    if let record = try messageRecord(chatID: message.id) {
      record.roomID = message.roomID
      record.content = message.content
      record.createdAt = message.createdAt
      record.updatedAt = message.updatedAt
      record.senderID = message.sender.id
      record.senderNick = message.sender.nick
      record.senderName = message.sender.name
      record.senderIntroduction = message.sender.introduction
      record.senderProfileImage = message.sender.profileImage
      record.senderHashTagSummary = ChatRecordCoding.summary(from: message.sender.hashTags)
      record.filePathSummary = ChatRecordCoding.summary(from: message.files)
    } else {
      context.insert(
        ChatMessageRecord(
          chatID: message.id,
          roomID: message.roomID,
          content: message.content,
          createdAt: message.createdAt,
          updatedAt: message.updatedAt,
          senderID: message.sender.id,
          senderNick: message.sender.nick,
          senderName: message.sender.name,
          senderIntroduction: message.sender.introduction,
          senderProfileImage: message.sender.profileImage,
          senderHashTags: message.sender.hashTags,
          filePaths: message.files
        )
      )
    }

    if let room = try roomRecord(roomID: message.roomID) {
      room.updatedAt = max(room.updatedAt, message.updatedAt)
    } else {
      context.insert(
        ChatRoomRecord(
          roomID: message.roomID,
          updatedAt: message.updatedAt,
          participantSummary: participantSummary(from: [message.sender])
        )
      )
    }

    try context.save()
  }

  func upsertMessages(_ messages: [ChatMessage]) throws {
    for message in messages {
      try upsertMessage(message)
    }
  }

  func markRoomSeen(roomID: String, at date: Date) throws {
    let record = try roomRecord(roomID: roomID) ?? ChatRoomRecord(
      roomID: roomID,
      updatedAt: date,
      participantSummary: ""
    )
    if record.modelContext == nil {
      context.insert(record)
    }
    record.lastLocalSeenAt = date
    try context.save()
  }

  private func messageRecord(chatID: String) throws -> ChatMessageRecord? {
    var descriptor = FetchDescriptor<ChatMessageRecord>()
    descriptor.includePendingChanges = true
    return try context.fetch(descriptor).first { $0.chatID == chatID }
  }

  private func roomRecord(roomID: String) throws -> ChatRoomRecord? {
    var descriptor = FetchDescriptor<ChatRoomRecord>()
    descriptor.includePendingChanges = true
    return try context.fetch(descriptor).first { $0.roomID == roomID }
  }

  private func participantSummary(from users: [ChatUser]) -> String {
    users
      .map { [$0.id, $0.nick, $0.name ?? "", $0.profileImage ?? ""].joined(separator: "\u{1F}") }
      .joined(separator: "\u{1E}")
  }

  private func users(from summary: String) -> [ChatUser] {
    guard summary.isEmpty == false else { return [] }
    return summary.split(separator: "\u{1E}", omittingEmptySubsequences: false).map { rawUser in
      let parts = rawUser.split(separator: "\u{1F}", omittingEmptySubsequences: false).map(String.init)
      return ChatUser(
        id: parts[safe: 0] ?? "",
        nick: parts[safe: 1] ?? "",
        name: parts[safe: 2].flatMap { $0.isEmpty ? nil : $0 },
        introduction: nil,
        profileImage: parts[safe: 3].flatMap { $0.isEmpty ? nil : $0 },
        hashTags: []
      )
    }
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
