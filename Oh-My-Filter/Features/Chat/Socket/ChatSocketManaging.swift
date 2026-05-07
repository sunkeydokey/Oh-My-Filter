import Foundation

@MainActor
protocol ChatSocketManaging: AnyObject {
  var onMessage: (@MainActor (ChatMessage) -> Void)? { get set }
  var onConnected: (@MainActor () -> Void)? { get set }
  var onDisconnected: (@MainActor () -> Void)? { get set }
  var onReconnectSucceeded: (@MainActor () -> Void)? { get set }
  var onReconnectAttempt: (@MainActor (Int) -> Void)? { get set }
  var onReconnectFailed: (@MainActor (String) -> Void)? { get set }

  func connect(roomID: String) async throws
  func disconnect()
}

@MainActor
final class NoOpChatSocketManager: ChatSocketManaging {
  var onMessage: (@MainActor (ChatMessage) -> Void)?
  var onConnected: (@MainActor () -> Void)?
  var onDisconnected: (@MainActor () -> Void)?
  var onReconnectSucceeded: (@MainActor () -> Void)?
  var onReconnectAttempt: (@MainActor (Int) -> Void)?
  var onReconnectFailed: (@MainActor (String) -> Void)?

  func connect(roomID: String) async throws {
    onConnected?()
  }

  func disconnect() {
    onDisconnected?()
  }
}
