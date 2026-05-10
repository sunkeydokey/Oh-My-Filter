import Foundation
import Testing
@testable import Oh_My_Filter

struct LiveChatServiceTests {
  @Test("current user load reads session store")
  func currentUserLoad() async throws {
    let manager = MockChatNetworkManager()
    let service = LiveChatService(
      networkManager: manager,
      userSessionStore: MockUserSessionStore(currentUserID: "user-current")
    )

    let userID = try await service.loadCurrentUserID()

    #expect(await manager.capturedURLs.isEmpty)
    #expect(userID == "user-current")
  }

  @Test("room list load decodes and sorts latest first")
  func roomListLoad() async throws {
    let manager = MockChatNetworkManager()
    let service = LiveChatService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.roomListData, statusCode: 200))
    let rooms = try await service.loadRooms()

    #expect(await manager.capturedURLs == ["http://filter.sesac.kr:42598/v1/chats"])
    #expect(rooms.map(\.id) == ["room-new", "room-old"])
  }

  @Test("message sync sends newest local date as next query")
  func messageSync() async throws {
    let manager = MockChatNetworkManager()
    let service = LiveChatService(networkManager: manager)
    let newestLocalCreatedAt = try ChatDateParser.date(from: "2026-04-21T10:00:00.000Z")

    await manager.enqueueResponse(NetworkResponse(data: Self.chatListData, statusCode: 200))
    let messages = try await service.syncMessages(
      roomID: "room-1",
      newestLocalCreatedAt: newestLocalCreatedAt
    )

    #expect(await manager.capturedURLs == ["http://filter.sesac.kr:42598/v1/chats/room-1"])
    #expect(await manager.capturedQueryItems == [
      [URLQueryItem(name: "next", value: newestLocalCreatedAt.formatted(.iso8601))],
    ])
    #expect(messages.map(\.id) == ["chat-1"])
  }

  @Test("send text maps success and server failure")
  func sendText() async throws {
    let manager = MockChatNetworkManager()
    let service = LiveChatService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.chatData(id: "sent-1"), statusCode: 200))
    let message = try await service.sendMessage(roomID: "room-1", text: "hello", files: ["/uploads/1.jpg"])
    #expect(message.id == "sent-1")
    #expect(await manager.capturedChatBodies == [ChatSendRequestDTO(content: "hello", files: ["/uploads/1.jpg"])])

    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 500))
    await #expect(throws: ChatServiceError.serverError) {
      _ = try await service.sendMessage(roomID: "room-1", text: "fail", files: [])
    }
  }

  @Test("file upload returns common file response paths")
  func fileUpload() async throws {
    let manager = MockChatNetworkManager()
    let service = LiveChatService(
      networkManager: manager,
      imageUploadUseCase: StubImageUploadUseCase()
    )
    let selection = PhotoPickerUploadSelection(data: Data("raw".utf8), fileName: "chat.jpg")

    await manager.enqueueResponse(NetworkResponse(data: Data(#"{"files":["/files/chat.jpg"]}"#.utf8), statusCode: 200))
    let files = try await service.uploadFiles(roomID: "room-1", selections: [selection], preset: .chat)

    #expect(files == ["/files/chat.jpg"])
    #expect(await manager.capturedURLs == ["http://filter.sesac.kr:42598/v1/chats/room-1/files"])
    #expect(await manager.capturedMultipartFiles == [
      [MultipartFilePart(fieldName: "files", fileName: "chat.jpg", mimeType: "image/jpeg", data: Data("jpeg".utf8))],
    ])
  }

  @Test("user search uses nick query and maps users")
  func userSearch() async throws {
    let manager = MockChatNetworkManager()
    let service = LiveChatService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.userSearchData, statusCode: 200))
    let users = try await service.searchUsers(nick: "윤새싹")

    #expect(await manager.capturedURLs == ["http://filter.sesac.kr:42598/v1/users/search"])
    #expect(await manager.capturedQueryItems == [[URLQueryItem(name: "nick", value: "윤새싹")]])
    #expect(users.map(\.nick) == ["윤새싹"])
  }

  @Test("create room posts opponent id and maps room")
  func createRoom() async throws {
    let manager = MockChatNetworkManager()
    let service = LiveChatService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.createdRoomData, statusCode: 200))
    let room = try await service.createRoom(opponentID: "user-1")

    #expect(await manager.capturedURLs == ["http://filter.sesac.kr:42598/v1/chats"])
    #expect(room.id == "room-new")
  }

  @Test("decode failure maps to decoding")
  func decodeFailure() async {
    let manager = MockChatNetworkManager()
    let service = LiveChatService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Data(#"{"data":[{}]}"#.utf8), statusCode: 200))
    await #expect(throws: ChatServiceError.decoding) {
      _ = try await service.loadRooms()
    }
  }
}

private struct MockUserSessionStore: UserSessionStoring {
  var currentUserIDValue: String?

  init(currentUserID: String?) {
    self.currentUserIDValue = currentUserID
  }

  func currentUserID() -> String? {
    currentUserIDValue
  }

  func localDataOwnerUserID() -> String? {
    currentUserIDValue
  }

  func saveAuthenticatedUserID(_ userID: String) {}

  func clearCurrentUserID() {}
}

private actor MockChatNetworkManager: AuthenticatedNetworkManaging {
  private var queuedResults: [Result<NetworkResponse, Error>] = []
  private(set) var capturedURLs: [String] = []
  private(set) var capturedChatBodies: [ChatSendRequestDTO] = []
  private(set) var capturedMultipartFiles: [[MultipartFilePart]] = []
  private var capturedParameters: [RequestQuery] = []

  var capturedParametersAreEmpty: [Bool] {
    capturedParameters.map(\.isEmpty)
  }

  var capturedQueryItems: [[URLQueryItem]] {
    capturedParameters.map(\.urlQueryItems)
  }

  func enqueueResponse(_ response: NetworkResponse) {
    queuedResults.append(.success(response))
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(router.url)
    capturedParameters.append(parameters)
    return try nextResult()
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(router.url)
    capturedParameters.append(parameters)
    if let body = body as? ChatSendRequestDTO {
      capturedChatBodies.append(body)
    }
    return try nextResult()
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    multipartFiles: [MultipartFilePart],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(router.url)
    capturedParameters.append(parameters)
    capturedMultipartFiles.append(multipartFiles)
    return try nextResult()
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }
    return try queuedResults.removeFirst().get()
  }
}

private struct StubImageUploadUseCase: ImageUploadUseCase {
  func multipartFiles(
    from selections: [PhotoPickerUploadSelection],
    preset: ImageUploadPreset
  ) throws -> [MultipartFilePart] {
    selections.map {
      MultipartFilePart(
        fieldName: preset.multipartFieldName,
        fileName: $0.fileName,
        mimeType: "image/jpeg",
        data: Data("jpeg".utf8)
      )
    }
  }
}

private extension LiveChatServiceTests {
  static let roomListData = Data(
    """
    {
      "data": [
        {
          "room_id": "room-old",
          "createdAt": "2026-04-20T10:00:00.000Z",
          "updatedAt": "2026-04-20T10:00:00.000Z",
          "participants": []
        },
        {
          "room_id": "room-new",
          "createdAt": "2026-04-21T10:00:00.000Z",
          "updatedAt": "2026-04-21T10:00:00.000Z",
          "participants": []
        }
      ]
    }
    """.utf8
  )

  static let chatListData = Data(
    """
    {
      "data": [
        {
          "chat_id": "chat-1",
          "room_id": "room-1",
          "content": "hello",
          "createdAt": "2026-04-21T10:00:00.000Z",
          "updatedAt": "2026-04-21T10:00:00.000Z",
          "sender": {
            "user_id": "user-1",
            "nick": "sesac",
            "hashTags": []
          },
          "files": []
        }
      ]
    }
    """.utf8
  )

  static func chatData(id: String) -> Data {
    Data(
      """
      {
        "chat_id": "\(id)",
        "room_id": "room-1",
        "content": "hello",
        "createdAt": "2026-04-21T10:00:00.000Z",
        "updatedAt": "2026-04-21T10:00:00.000Z",
        "sender": {
          "user_id": "user-1",
          "nick": "sesac",
          "hashTags": []
        },
        "files": []
      }
      """.utf8
    )
  }

  static let userSearchData = Data(
    """
    {
      "data": [
        {
          "user_id": "user-1",
          "nick": "윤새싹",
          "name": "새싹",
          "introduction": "필터를 좋아해요",
          "profileImage": null,
          "hashTags": []
        }
      ]
    }
    """.utf8
  )

  static let createdRoomData = Data(
    """
    {
      "room_id": "room-new",
      "createdAt": "2026-04-21T10:00:00.000Z",
      "updatedAt": "2026-04-21T10:00:00.000Z",
      "participants": [
        {
          "user_id": "user-1",
          "nick": "윤새싹",
          "hashTags": []
        }
      ]
    }
    """.utf8
  )
}
