import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct ChatListViewModelTests {
  @Test("open room selects existing local room")
  func openRoomSelectsExistingLocalRoom() async throws {
    let room = ChatRoom.fixture(id: "room-1")
    let store = ChatListMemoryStore(rooms: [room])
    let viewModel = ChatListViewModel(
      service: ChatListFakeService(rooms: []),
      store: store
    )

    await viewModel.send(.openRoom("room-1"))

    #expect(viewModel.state.selectedRoom == room)
  }

  @Test("open room loads remote rooms before selecting")
  func openRoomLoadsRemoteRoomsBeforeSelecting() async throws {
    let room = ChatRoom.fixture(id: "room-2")
    let service = ChatListFakeService(rooms: [room])
    let store = ChatListMemoryStore()
    let viewModel = ChatListViewModel(
      service: service,
      store: store
    )

    await viewModel.send(.openRoom("room-2"))

    #expect(viewModel.state.selectedRoom == room)
    #expect(await service.loadRoomsCallCount == 1)
  }
}

private actor ChatListFakeService: ChatServicing {
  private let rooms: [ChatRoom]
  private(set) var loadRoomsCallCount = 0

  init(rooms: [ChatRoom]) {
    self.rooms = rooms
  }

  func loadCurrentUserID() async throws -> String {
    "user-1"
  }

  func loadRooms() async throws -> [ChatRoom] {
    loadRoomsCallCount += 1
    return rooms
  }

  func createRoom(opponentID: String) async throws -> ChatRoom {
    ChatRoom.fixture(id: "created-\(opponentID)")
  }

  func searchUsers(nick: String) async throws -> [ChatUser] {
    []
  }

  func syncMessages(roomID: String, newestLocalCreatedAt: Date?) async throws -> [ChatMessage] {
    []
  }

  func uploadFiles(
    roomID: String,
    selections: [PhotoPickerUploadSelection],
    preset: ImageUploadPreset
  ) async throws -> [String] {
    []
  }

  func sendMessage(roomID: String, text: String, files: [String]) async throws -> ChatMessage {
    ChatMessage.fixture(roomID: roomID)
  }
}

@MainActor
private final class ChatListMemoryStore: ChatLocalStoring {
  private var rooms: [ChatRoom]

  init(rooms: [ChatRoom] = []) {
    self.rooms = rooms
  }

  func fetchRooms() throws -> [ChatRoom] {
    rooms
  }

  func fetchMessages(roomID: String) throws -> [ChatMessage] {
    []
  }

  func newestMessageDate(roomID: String) throws -> Date? {
    nil
  }

  func lastSeenAt(roomID: String) throws -> Date? {
    nil
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

  func upsertMessage(_ message: ChatMessage) throws {}

  func upsertMessages(_ messages: [ChatMessage]) throws {}

  func markRoomSeen(roomID: String, at date: Date) throws {}
}

private extension ChatRoom {
  static func fixture(id: String) -> ChatRoom {
    ChatRoom(
      id: id,
      updatedAt: Date(timeIntervalSinceReferenceDate: 1_000),
      participants: [.fixture(id: "user-1"), .fixture(id: "user-2")],
      lastMessage: .fixture(roomID: id),
      lastSeenAt: nil
    )
  }
}

private extension ChatMessage {
  static func fixture(roomID: String) -> ChatMessage {
    ChatMessage(
      id: "chat-\(roomID)",
      roomID: roomID,
      content: "hello",
      createdAt: Date(timeIntervalSinceReferenceDate: 1_000),
      updatedAt: Date(timeIntervalSinceReferenceDate: 1_000),
      sender: .fixture(id: "user-2"),
      files: []
    )
  }
}

private extension ChatUser {
  static func fixture(id: String) -> ChatUser {
    ChatUser(
      id: id,
      nick: id,
      name: nil,
      introduction: nil,
      profileImage: nil,
      hashTags: []
    )
  }
}
