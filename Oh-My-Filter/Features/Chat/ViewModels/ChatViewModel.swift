import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class ChatViewModel {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "ChatViewModel"
  )

  private(set) var state: ChatState

  private let service: any ChatServicing
  private let store: any ChatLocalStoring
  private let socketManager: any ChatSocketManaging
  private var hasLoaded = false

  init(
    room: ChatRoom,
    currentUserID: String,
    service: any ChatServicing,
    store: any ChatLocalStoring,
    socketManager: any ChatSocketManaging
  ) {
    self.state = ChatState(
      roomID: room.id,
      title: Self.title(for: room, currentUserID: currentUserID),
      subtitle: "온라인",
      currentUserID: currentUserID
    )
    self.service = service
    self.store = store
    self.socketManager = socketManager
    configureSocket()
  }

  func send(_ action: ChatAction) async {
    switch action {
    case .task:
      guard hasLoaded == false else { return }
      hasLoaded = true
      await load()
    case .disappear:
      socketManager.disconnect()
      state.connectionState = .disconnected
      try? store.markRoomSeen(roomID: state.roomID, at: .now)
    case let .composerChanged(text):
      state.composerText = text
    case .sendTapped:
      await sendMessage(text: state.composerText)
    case .retryPending:
      guard let pending = state.alert else { return }
      state.alert = nil
      await sendMessage(text: pending.text)
    case .deletePending:
      state.alert = nil
    }
  }

  private func load() async {
    do {
      state.messages = try store.fetchMessages(roomID: state.roomID)
      let newestLocalDate = try store.newestMessageDate(roomID: state.roomID)
      state.connectionState = .syncing

      let remoteMessages = try await service.syncMessages(
        roomID: state.roomID,
        newestLocalCreatedAt: newestLocalDate
      )
      try store.upsertMessages(remoteMessages)
      state.messages = try store.fetchMessages(roomID: state.roomID)
      try store.markRoomSeen(roomID: state.roomID, at: .now)

      try await socketManager.connect(roomID: state.roomID)
    } catch is CancellationError {
      return
    } catch {
      state.connectionState = .disconnected
    }
  }

  private func sendMessage(text: String) async {
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmedText.isEmpty == false else { return }

    state.composerText = ""
    do {
      let message = try await service.sendMessage(roomID: state.roomID, text: trimmedText)
      try store.upsertMessage(message)
      state.messages = try store.fetchMessages(roomID: state.roomID)
      try store.markRoomSeen(roomID: state.roomID, at: message.createdAt)
    } catch {
      state.alert = ChatPendingMessageAlert(
        text: trimmedText,
        message: "메시지를 보내지 못했습니다."
      )
    }
  }

  private func configureSocket() {
    socketManager.onConnected = { [weak self] in
      self?.state.connectionState = .connected
    }
    socketManager.onDisconnected = { [weak self] in
      self?.state.connectionState = .disconnected
    }
    socketManager.onMessage = { [weak self] message in
      guard let self else { return }
      do {
        Self.logger.debug("[ChatViewModel] socket message handling started chatID=\(message.id, privacy: .public) roomID=\(message.roomID, privacy: .public)")
        try self.store.upsertMessage(message)
        self.state.messages = try self.store.fetchMessages(roomID: self.state.roomID)
        try self.store.markRoomSeen(roomID: self.state.roomID, at: message.createdAt)
        Self.logger.debug("[ChatViewModel] socket message stored and UI state refreshed chatID=\(message.id, privacy: .public) visibleMessages=\(self.state.messages.count, privacy: .public)")
      } catch {
        Self.logger.error("[ChatViewModel] socket message persistence failed chatID=\(message.id, privacy: .public) error=\(String(describing: error), privacy: .public)")
        return
      }
    }
  }

  private static func title(for room: ChatRoom, currentUserID: String) -> String {
    let otherUsers = room.participants.filter { $0.id != currentUserID }
    if let first = otherUsers.first ?? room.participants.first {
      return first.nick
    }
    return "채팅"
  }
}
