import Foundation

protocol ChatServicing: Sendable {
  func loadCurrentUserID() async throws -> String
  func loadRooms() async throws -> [ChatRoom]
  func createRoom(opponentID: String) async throws -> ChatRoom
  func searchUsers(nick: String) async throws -> [ChatUser]
  func syncMessages(roomID: String, newestLocalCreatedAt: Date?) async throws -> [ChatMessage]
  func sendMessage(roomID: String, text: String) async throws -> ChatMessage
}

enum ChatServiceError: Error, Equatable, Sendable {
  case transport
  case serverError
  case decoding
  case emptyCurrentUser
}
