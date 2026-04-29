import Foundation
import SwiftData
import Testing
@testable import Oh_My_Filter

@MainActor
@Suite(.serialized)
struct SwiftDataChatStoreTests {
  @Test("message upsert replaces by chat id")
  func messageUpsertByChatID() throws {
    let store = try makeStore()

    try store.upsertMessage(.message(id: "chat-1", content: "first"))
    try store.upsertMessage(.message(id: "chat-1", content: "updated"))

    let messages = try store.fetchMessages(roomID: "room-1")
    #expect(messages.count == 1)
    #expect(messages[0].content == "updated")
  }

  @Test("room unread compares updated at to local seen timestamp")
  func unreadCalculation() throws {
    let store = try makeStore()
    let updatedAt = try ChatDateParser.date(from: "2026-04-21T10:00:00.000Z")
    let seenAt = try ChatDateParser.date(from: "2026-04-21T09:00:00.000Z")

    try store.upsertRoom(.room(id: "room-1", updatedAt: updatedAt, lastSeenAt: seenAt))
    let room = try #require(store.fetchRooms().first)
    #expect(room.isUnread)

    try store.markRoomSeen(roomID: "room-1", at: updatedAt.addingTimeInterval(1))
    let seenRoom = try #require(store.fetchRooms().first)
    #expect(seenRoom.isUnread == false)
  }

  @Test("room fetch sorts latest first")
  func sortedRooms() throws {
    let store = try makeStore()

    try store.upsertRoom(.room(id: "old", updatedAt: try ChatDateParser.date(from: "2026-04-20T10:00:00.000Z")))
    try store.upsertRoom(.room(id: "new", updatedAt: try ChatDateParser.date(from: "2026-04-21T10:00:00.000Z")))

    #expect(try store.fetchRooms().map(\.id) == ["new", "old"])
  }

  private func makeStore() throws -> SwiftDataChatStore {
    let configuration = ModelConfiguration("ChatStoreTests-\(UUID().uuidString)", isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: ChatRoomRecord.self,
      ChatMessageRecord.self,
      configurations: configuration
    )
    return SwiftDataChatStore(container: container)
  }
}

private extension ChatMessage {
  static func message(id: String, content: String = "hello") throws -> ChatMessage {
    ChatMessage(
      id: id,
      roomID: "room-1",
      content: content,
      createdAt: try ChatDateParser.date(from: "2026-04-21T10:00:00.000Z"),
      updatedAt: try ChatDateParser.date(from: "2026-04-21T10:00:00.000Z"),
      sender: ChatUser(id: "user-1", nick: "sesac", name: nil, introduction: nil, profileImage: nil, hashTags: []),
      files: []
    )
  }
}

private extension ChatRoom {
  static func room(id: String, updatedAt: Date, lastSeenAt: Date? = nil) -> ChatRoom {
    ChatRoom(
      id: id,
      updatedAt: updatedAt,
      participants: [ChatUser(id: "user-1", nick: "sesac", name: nil, introduction: nil, profileImage: nil, hashTags: [])],
      lastMessage: nil,
      lastSeenAt: lastSeenAt
    )
  }
}
