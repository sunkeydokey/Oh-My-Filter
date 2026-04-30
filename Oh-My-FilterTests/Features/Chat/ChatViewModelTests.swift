import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct ChatViewModelTests {
  @Test("chat load is local first, then server sync, then socket connect")
  func localFirstThenSyncThenSocket() async throws {
    let store = InMemoryChatStore()
    let localMessage = try ChatMessage.fixture(id: "local", content: "local")
    let remoteMessage = try ChatMessage.fixture(id: "remote", content: "remote")
    try store.upsertMessage(localMessage)

    let service = FakeChatService()
    await service.setMessages([remoteMessage])
    let socket = SpyChatSocketManager()
    let viewModel = ChatViewModel(
      room: try .fixture(id: "room-1"),
      currentUserID: "me",
      service: service,
      store: store,
      socketManager: socket
    )

    await viewModel.send(.task)

    #expect(viewModel.state.messages.map(\.id) == ["local", "remote"])
    #expect(await service.syncCallCount == 1)
    #expect(await service.syncNewestLocalCreatedAtValues == [localMessage.createdAt])
    #expect(socket.connectedRoomIDs == ["room-1"])
    #expect(viewModel.state.connectionState == .connected)
  }

  @Test("socket message upserts into visible messages")
  func socketMessageUpsert() async throws {
    let store = InMemoryChatStore()
    let service = FakeChatService()
    let socket = SpyChatSocketManager()
    let viewModel = ChatViewModel(
      room: try .fixture(id: "room-1"),
      currentUserID: "me",
      service: service,
      store: store,
      socketManager: socket
    )
    await viewModel.send(.task)

    socket.emit(message: try .fixture(id: "socket", content: "received"))

    #expect(try store.fetchMessages(roomID: "room-1").map(\.id) == ["socket"])
    #expect(viewModel.state.messages.map(\.id) == ["socket"])
    #expect(try store.lastSeenAt(roomID: "room-1") == viewModel.state.messages[0].createdAt)
  }

  @Test("send failure exposes retry and delete alert state")
  func sendRetryDeleteAlert() async throws {
    let store = InMemoryChatStore()
    let service = FakeChatService()
    await service.setSendResult(.failure(ChatServiceError.serverError))
    let viewModel = ChatViewModel(
      room: try .fixture(id: "room-1"),
      currentUserID: "me",
      service: service,
      store: store,
      socketManager: SpyChatSocketManager()
    )

    await viewModel.send(.composerChanged(" hello "))
    await viewModel.send(.sendTapped)

    #expect(viewModel.state.alert?.text == "hello")

    await service.setSendResult(.success(try .fixture(id: "sent", content: "hello")))
    await viewModel.send(.retryPending)
    #expect(viewModel.state.alert == nil)
    #expect(viewModel.state.messages.map(\.id) == ["sent"])

    await service.setSendResult(.failure(ChatServiceError.serverError))
    await viewModel.send(.composerChanged("delete me"))
    await viewModel.send(.sendTapped)
    await viewModel.send(.deletePending)
    #expect(viewModel.state.alert == nil)
  }

  @Test("chat list filters search and unread rooms")
  func chatListSearchAndUnreadFiltering() async throws {
    let store = InMemoryChatStore()
    let oldSeen = try ChatDateParser.date(from: "2026-04-21T09:00:00.000Z")
    let currentSeen = try ChatDateParser.date(from: "2026-04-21T10:00:01.000Z")
    try store.markRoomSeen(roomID: "room-1", at: oldSeen)
    try store.markRoomSeen(roomID: "room-2", at: currentSeen)
    let service = FakeChatService()
    await service.setRooms([
      try .fixture(id: "room-1", participantNick: "윤새싹", lastMessage: try .fixture(id: "c1", content: "회의 자료")),
      try .fixture(id: "room-2", participantNick: "디자인팀", lastMessage: try .fixture(id: "c2", content: "초대")),
    ])
    let viewModel = ChatListViewModel(service: service, store: store)

    await viewModel.send(.task)
    await viewModel.send(.searchChanged("회의"))
    #expect(viewModel.state.visibleRooms.map(\.id) == ["room-1"])

    await viewModel.send(.searchChanged(""))
    await viewModel.send(.filterChanged(.unread))
    #expect(viewModel.state.visibleRooms.map(\.id) == ["room-1"])
  }

  @Test("chat list debounces user search")
  func chatListDebouncedUserSearch() async throws {
    let store = InMemoryChatStore()
    let service = FakeChatService()
    await service.setSearchUsers([
      ChatUser(id: "user-1", nick: "윤새싹", name: nil, introduction: nil, profileImage: nil, hashTags: []),
    ])
    let viewModel = ChatListViewModel(service: service, store: store)

    await viewModel.send(.searchChanged("윤"))
    await viewModel.send(.searchChanged("윤새싹"))
    try await Task.sleep(for: .milliseconds(1_100))

    #expect(await service.searchNicks == ["윤새싹"])
    #expect(viewModel.state.searchResults.map(\.id) == ["user-1"])

    await viewModel.send(.searchChanged(""))
    #expect(viewModel.state.searchResults.isEmpty)
  }

  @Test("chat list search result tap creates and selects room")
  func chatListSearchResultTapCreatesRoom() async throws {
    let store = InMemoryChatStore()
    let service = FakeChatService()
    let room = try ChatRoom.fixture(id: "room-new", participantNick: "윤새싹")
    await service.setCreateRoom(room)
    let viewModel = ChatListViewModel(service: service, store: store)

    await viewModel.send(.searchResultTapped(ChatUser(
      id: "user-1",
      nick: "윤새싹",
      name: nil,
      introduction: nil,
      profileImage: nil,
      hashTags: []
    )))

    #expect(await service.createdOpponentIDs == ["user-1"])
    #expect(viewModel.state.selectedRoom?.id == "room-new")
    #expect(viewModel.state.rooms.map(\.id) == ["room-new"])

    await viewModel.send(.selectedRoomCleared)
    #expect(viewModel.state.selectedRoom == nil)
  }
}

private actor FakeChatService: ChatServicing {
  private var rooms: [ChatRoom] = []
  private var messages: [ChatMessage] = []
  private var searchUsers: [ChatUser] = []
  private var createdRoom: ChatRoom?
  private var sendResult: Result<ChatMessage, Error>?
  private(set) var syncCallCount = 0
  private(set) var syncNewestLocalCreatedAtValues: [Date?] = []
  private(set) var searchNicks: [String] = []
  private(set) var createdOpponentIDs: [String] = []

  func setRooms(_ rooms: [ChatRoom]) {
    self.rooms = rooms
  }

  func setMessages(_ messages: [ChatMessage]) {
    self.messages = messages
  }

  func setSearchUsers(_ searchUsers: [ChatUser]) {
    self.searchUsers = searchUsers
  }

  func setCreateRoom(_ createRoom: ChatRoom) {
    self.createdRoom = createRoom
  }

  func setSendResult(_ result: Result<ChatMessage, Error>) {
    sendResult = result
  }

  func loadCurrentUserID() async throws -> String {
    "me"
  }

  func loadRooms() async throws -> [ChatRoom] {
    rooms
  }

  func searchUsers(nick: String) async throws -> [ChatUser] {
    searchNicks.append(nick)
    return searchUsers
  }

  func createRoom(opponentID: String) async throws -> ChatRoom {
    createdOpponentIDs.append(opponentID)
    if let createdRoom {
      return createdRoom
    }
    return try .fixture(id: "created-room")
  }

  func syncMessages(roomID: String, newestLocalCreatedAt: Date?) async throws -> [ChatMessage] {
    syncCallCount += 1
    syncNewestLocalCreatedAtValues.append(newestLocalCreatedAt)
    return messages
  }

  func sendMessage(roomID: String, text: String) async throws -> ChatMessage {
    try sendResult?.get() ?? .fixture(id: "sent", content: text)
  }
}

@MainActor
private final class SpyChatSocketManager: ChatSocketManaging {
  var onMessage: (@MainActor (ChatMessage) -> Void)?
  var onConnected: (@MainActor () -> Void)?
  var onDisconnected: (@MainActor () -> Void)?
  private(set) var connectedRoomIDs: [String] = []

  func connect(roomID: String) async throws {
    connectedRoomIDs.append(roomID)
    onConnected?()
  }

  func disconnect() {
    onDisconnected?()
  }

  func emit(message: ChatMessage) {
    onMessage?(message)
  }
}

@MainActor
private final class InMemoryChatStore: ChatLocalStoring {
  private var rooms: [ChatRoom] = []
  private var messages: [ChatMessage] = []
  private var seenAtByRoomID: [String: Date] = [:]

  func fetchRooms() throws -> [ChatRoom] {
    rooms
      .map { room in
        ChatRoom(
          id: room.id,
          updatedAt: room.updatedAt,
          participants: room.participants,
          lastMessage: messages.filter { $0.roomID == room.id }.last ?? room.lastMessage,
          lastSeenAt: seenAtByRoomID[room.id] ?? room.lastSeenAt
        )
      }
      .sorted { $0.updatedAt > $1.updatedAt }
  }

  func fetchMessages(roomID: String) throws -> [ChatMessage] {
    messages.filter { $0.roomID == roomID }.sorted { $0.createdAt < $1.createdAt }
  }

  func newestMessageDate(roomID: String) throws -> Date? {
    try fetchMessages(roomID: roomID).last?.createdAt
  }

  func lastSeenAt(roomID: String) throws -> Date? {
    seenAtByRoomID[roomID]
  }

  func upsertRoom(_ room: ChatRoom) throws {
    rooms.removeAll { $0.id == room.id }
    rooms.append(room)
  }

  func upsertRooms(_ rooms: [ChatRoom]) throws {
    for room in rooms {
      try upsertRoom(room)
    }
  }

  func upsertMessage(_ message: ChatMessage) throws {
    messages.removeAll { $0.id == message.id }
    messages.append(message)
  }

  func upsertMessages(_ messages: [ChatMessage]) throws {
    for message in messages {
      try upsertMessage(message)
    }
  }

  func markRoomSeen(roomID: String, at date: Date) throws {
    seenAtByRoomID[roomID] = date
  }
}

private extension ChatRoom {
  static func fixture(
    id: String,
    participantNick: String = "윤새싹",
    lastMessage: ChatMessage? = nil,
    lastSeenAt: Date? = nil
  ) throws -> ChatRoom {
    ChatRoom(
      id: id,
      updatedAt: try ChatDateParser.date(from: "2026-04-21T10:00:00.000Z"),
      participants: [
        ChatUser(id: "other", nick: participantNick, name: nil, introduction: nil, profileImage: nil, hashTags: []),
      ],
      lastMessage: lastMessage,
      lastSeenAt: lastSeenAt
    )
  }
}

private extension ChatMessage {
  static func fixture(id: String, content: String) throws -> ChatMessage {
    ChatMessage(
      id: id,
      roomID: "room-1",
      content: content,
      createdAt: try ChatDateParser.date(from: "2026-04-21T10:00:00.000Z").addingTimeInterval(id == "local" ? 0 : 1),
      updatedAt: try ChatDateParser.date(from: "2026-04-21T10:00:00.000Z").addingTimeInterval(id == "local" ? 0 : 1),
      sender: ChatUser(id: "other", nick: "윤새싹", name: nil, introduction: nil, profileImage: nil, hashTags: []),
      files: []
    )
  }
}
