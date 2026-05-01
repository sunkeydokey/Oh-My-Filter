import Foundation

protocol ChatServicing: Sendable {
  func loadCurrentUserID() async throws -> String
  func loadRooms() async throws -> [ChatRoom]
  func createRoom(opponentID: String) async throws -> ChatRoom
  func searchUsers(nick: String) async throws -> [ChatUser]
  func syncMessages(roomID: String, newestLocalCreatedAt: Date?) async throws -> [ChatMessage]
  func uploadFiles(
    roomID: String,
    selections: [PhotoPickerUploadSelection],
    preset: ImageUploadPreset
  ) async throws -> [String]
  func sendMessage(roomID: String, text: String, files: [String]) async throws -> ChatMessage
}

enum ChatServiceError: Error, Equatable, Sendable {
  case transport
  case serverError
  case decoding
  case emptyCurrentUser
}

extension ChatServicing {
  func sendMessage(roomID: String, text: String) async throws -> ChatMessage {
    try await sendMessage(roomID: roomID, text: text, files: [])
  }
}
