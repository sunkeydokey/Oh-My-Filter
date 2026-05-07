import Foundation
import OSLog
import SocketIO

@MainActor
final class SocketIOChatSocketManager: ChatSocketManaging {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "ChatSocket"
  )

  var onMessage: (@MainActor (ChatMessage) -> Void)?
  var onConnected: (@MainActor () -> Void)?
  var onDisconnected: (@MainActor () -> Void)?
  var onReconnectSucceeded: (@MainActor () -> Void)?

  private let tokenCoordinator: any TokenRefreshCoordinating
  private let decoder: JSONDecoder
  private var manager: SocketManager?
  private var socket: SocketIOClient?
  private var connectedRoomID: String?
  private var connectedNamespace: String?

  init(
    tokenCoordinator: any TokenRefreshCoordinating = AppTokenRefreshCoordinator.shared,
    decoder: JSONDecoder = LiveChatService.makeDecoder()
  ) {
    self.tokenCoordinator = tokenCoordinator
    self.decoder = decoder
  }

  func connect(roomID: String) async throws {
    resetExistingConnection()

    let accessToken = try await tokenCoordinator.authorizationHeaderValue()
    let url = try Self.socketBaseURL()
    let namespace = "/chats-\(roomID)"

    let manager = SocketManager(
      socketURL: url,
      config: [
        .log(false),
        .compress,
        .forceWebsockets(true),
        .extraHeaders([
          "SeSACKey": Server.apiKey(),
          "Authorization": accessToken,
        ]),
      ]
    )
    let socket = manager.socket(forNamespace: namespace)

    socket.on(clientEvent: .connect) { [weak self] _, _ in
      Task { @MainActor in
        Self.logger.info("[ChatSocket] connected roomID=\(roomID, privacy: .public) namespace=\(namespace, privacy: .public)")
        self?.onConnected?()
      }
    }
    socket.on(clientEvent: .disconnect) { [weak self] _, _ in
      Task { @MainActor in
        Self.logger.info("[ChatSocket] disconnected roomID=\(roomID, privacy: .public) namespace=\(namespace, privacy: .public)")
        self?.onDisconnected?()
      }
    }
    socket.on(clientEvent: .error) { data, _ in
      Task { @MainActor in
        Self.logger.error("[ChatSocket] error roomID=\(roomID, privacy: .public) namespace=\(namespace, privacy: .public) data=\(String(describing: data), privacy: .public)")
      }
    }
    socket.on("chat") { [weak self] data, _ in
      guard let self else { return }
      Task { @MainActor in
        guard let payload = data.first else {
          Self.logger.error("[ChatSocket] chat event received without payload roomID=\(roomID, privacy: .public)")
          return
        }
        do {
          let payloadData = try Self.data(from: payload)
          let dto = try self.decoder.decode(ChatResponseDTO.self, from: payloadData)
          let message = try dto.domain()
          Self.logger.info("[ChatSocket] chat received chatID=\(message.id, privacy: .public) roomID=\(message.roomID, privacy: .public) senderID=\(message.sender.id, privacy: .public) files=\(message.files.count, privacy: .public)")
          self.onMessage?(message)
        } catch {
          Self.logger.error("[ChatSocket] chat decode failed roomID=\(roomID, privacy: .public) error=\(String(describing: error), privacy: .public)")
          return
        }
      }
    }

    self.manager = manager
    self.socket = socket
    connectedRoomID = roomID
    connectedNamespace = namespace
    socket.connect()
  }

  func disconnect() {
    guard let socket else { return }

    let roomID = connectedRoomID ?? "unknown"
    let namespace = connectedNamespace ?? "unknown"
    socket.removeAllHandlers()
    socket.disconnect()
    Self.logger.info("[ChatSocket] disconnected roomID=\(roomID, privacy: .public) namespace=\(namespace, privacy: .public)")
    onDisconnected?()
    self.socket = nil
    manager = nil
    connectedRoomID = nil
    connectedNamespace = nil
  }

  private func resetExistingConnection() {
    socket?.removeAllHandlers()
    socket?.disconnect()
    socket = nil
    manager = nil
    connectedRoomID = nil
    connectedNamespace = nil
  }

  private static func socketBaseURL() throws -> URL {
    guard var components = URLComponents(string: Server.baseUrl()) else {
      throw ChatServiceError.serverError
    }
    components.path = ""
    components.query = nil
    guard let url = components.url else {
      throw ChatServiceError.serverError
    }
    return url
  }

  private static func data(from payload: Any) throws -> Data {
    if let data = payload as? Data {
      return data
    }
    if let dictionary = payload as? [String: Any] {
      return try JSONSerialization.data(withJSONObject: dictionary)
    }
    if let array = payload as? [Any] {
      return try JSONSerialization.data(withJSONObject: array)
    }
    throw ChatServiceError.decoding
  }
}
