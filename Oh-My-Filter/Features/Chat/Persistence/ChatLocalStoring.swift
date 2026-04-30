import Foundation

@MainActor
protocol ChatLocalStoring: AnyObject {
  func fetchRooms() throws -> [ChatRoom]
  func fetchMessages(roomID: String) throws -> [ChatMessage]
  func newestMessageDate(roomID: String) throws -> Date?
  func lastSeenAt(roomID: String) throws -> Date?
  func upsertRoom(_ room: ChatRoom) throws
  func upsertRooms(_ rooms: [ChatRoom]) throws
  func upsertMessage(_ message: ChatMessage) throws
  func upsertMessages(_ messages: [ChatMessage]) throws
  func markRoomSeen(roomID: String, at date: Date) throws
}
