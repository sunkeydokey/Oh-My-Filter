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
  var onReconnectAttempt: (@MainActor (Int) -> Void)?
  var onReconnectFailed: (@MainActor (String) -> Void)?

  private let tokenCoordinator: any TokenRefreshCoordinating
  private let decoder: JSONDecoder
  private var manager: SocketManager?
  private var socket: SocketIOClient?
  private var connectedRoomID: String?
  private var connectedNamespace: String?
  private let reconnectionManager = ReconnectionManager()
  private var isManualDisconnect = false

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
        guard let self else { return }
        Self.logger.info("[ChatSocket] disconnected roomID=\(roomID, privacy: .public) namespace=\(namespace, privacy: .public)")
        if self.isManualDisconnect {
          self.isManualDisconnect = false
          self.onDisconnected?()
          return
        }
        if self.reconnectionManager.hasReachedMaxAttempts {
          self.onReconnectFailed?("연결을 복구할 수 없습니다.")
          return
        }
        self.reconnectionManager.scheduleNext { [weak self] in
          await self?.attemptReconnect()
        }
        self.onReconnectAttempt?(self.reconnectionManager.attempt)
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

    isManualDisconnect = true
    reconnectionManager.cancel()

    let roomID = connectedRoomID ?? "unknown"
    let namespace = connectedNamespace ?? "unknown"
    socket.removeAllHandlers()
    socket.disconnect()
    Self.logger.info("[ChatSocket] manual disconnect roomID=\(roomID, privacy: .public) namespace=\(namespace, privacy: .public)")
    self.socket = nil
    manager = nil
    connectedRoomID = nil
    connectedNamespace = nil
  }

  private func attemptReconnect() async {
    guard let roomID = connectedRoomID else {
      onReconnectFailed?("연결을 복구할 수 없습니다.")
      return
    }

    Self.logger.info("[ChatSocket] reconnect attempt=\(self.reconnectionManager.attempt, privacy: .public) roomID=\(roomID, privacy: .public)")

    do {
      let accessToken = try await tokenCoordinator.authorizationHeaderValue()
      let url = try Self.socketBaseURL()
      let namespace = "/chats-\(roomID)"

      let newManager = SocketManager(
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
      let newSocket = newManager.socket(forNamespace: namespace)

      newSocket.on(clientEvent: .connect) { [weak self] _, _ in
        Task { @MainActor in
          guard let self else { return }
          Self.logger.info("[ChatSocket] reconnect succeeded roomID=\(roomID, privacy: .public)")
          self.reconnectionManager.reset()
          self.onReconnectSucceeded?()
        }
      }
      newSocket.on(clientEvent: .disconnect) { [weak self] _, _ in
        Task { @MainActor in
          guard let self else { return }
          Self.logger.info("[ChatSocket] disconnected after reconnect roomID=\(roomID, privacy: .public)")
          if self.isManualDisconnect {
            self.isManualDisconnect = false
            self.onDisconnected?()
            return
          }
          if self.reconnectionManager.hasReachedMaxAttempts {
            self.onReconnectFailed?("연결을 복구할 수 없습니다.")
            return
          }
          self.reconnectionManager.scheduleNext { [weak self] in
            await self?.attemptReconnect()
          }
          self.onReconnectAttempt?(self.reconnectionManager.attempt)
        }
      }
      newSocket.on(clientEvent: .error) { data, _ in
        Task { @MainActor in
          Self.logger.error("[ChatSocket] error during reconnect roomID=\(roomID, privacy: .public) data=\(String(describing: data), privacy: .public)")
        }
      }
      newSocket.on("chat") { [weak self] data, _ in
        guard let self else { return }
        Task { @MainActor in
          guard let payload = data.first else { return }
          do {
            let payloadData = try Self.data(from: payload)
            let dto = try self.decoder.decode(ChatResponseDTO.self, from: payloadData)
            let message = try dto.domain()
            self.onMessage?(message)
          } catch {
            Self.logger.error("[ChatSocket] chat decode failed during reconnect roomID=\(roomID, privacy: .public) error=\(String(describing: error), privacy: .public)")
          }
        }
      }

      self.manager = newManager
      self.socket = newSocket
      self.connectedNamespace = namespace
      newSocket.connect()
    } catch {
      Self.logger.error("[ChatSocket] reconnect failed error=\(String(describing: error), privacy: .public)")
      if reconnectionManager.hasReachedMaxAttempts {
        onReconnectFailed?("연결을 복구할 수 없습니다.")
      } else {
        reconnectionManager.scheduleNext { [weak self] in
          await self?.attemptReconnect()
        }
        onReconnectAttempt?(reconnectionManager.attempt)
      }
    }
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
