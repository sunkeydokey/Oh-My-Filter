import Foundation

@MainActor
protocol ChatSocketManaging: AnyObject {
  var onMessage: (@MainActor (ChatMessage) -> Void)? { get set }
  var onConnected: (@MainActor () -> Void)? { get set }
  var onDisconnected: (@MainActor () -> Void)? { get set }

  func connect(roomID: String) async throws
  func disconnect()
}

@MainActor
final class NoOpChatSocketManager: ChatSocketManaging {
  var onMessage: (@MainActor (ChatMessage) -> Void)?
  var onConnected: (@MainActor () -> Void)?
  var onDisconnected: (@MainActor () -> Void)?

  func connect(roomID: String) async throws {
    onConnected?()
  }

  func disconnect() {
    onDisconnected?()
  }
}
