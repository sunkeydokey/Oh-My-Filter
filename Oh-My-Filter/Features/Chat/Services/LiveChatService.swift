import Foundation

nonisolated struct LiveChatService: ChatServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let decoder: JSONDecoder
  private let imageUploadUseCase: any ImageUploadUseCase
  private let userSessionStore: any UserSessionStoring

  @MainActor
  init() {
    self.init(networkManager: AuthenticatedNetworkManager())
  }

  init(
    networkManager: any AuthenticatedNetworkManaging,
    decoder: JSONDecoder = LiveChatService.makeDecoder(),
    imageUploadUseCase: any ImageUploadUseCase = LiveImageUploadUseCase(),
    userSessionStore: any UserSessionStoring = AppUserSessionStore()
  ) {
    self.networkManager = networkManager
    self.decoder = decoder
    self.imageUploadUseCase = imageUploadUseCase
    self.userSessionStore = userSessionStore
  }

  func loadCurrentUserID() async throws -> String {
    guard let currentUserID = userSessionStore.currentUserID(),
          currentUserID.isEmpty == false else {
      throw ChatServiceError.emptyCurrentUser
    }
    return currentUserID
  }

  func loadRooms() async throws -> [ChatRoom] {
    do {
      let response = try await networkManager.request(ChatApiRouter.roomList)
      guard (200..<300).contains(response.statusCode) else {
        throw ChatServiceError.serverError
      }
      let dto = try decoder.decode(ChatRoomListResponseDTO.self, from: response.data)
      return try dto.data
        .map { try $0.domain(lastSeenAt: nil) }
        .sorted { $0.updatedAt > $1.updatedAt }
    } catch let error as ChatServiceError {
      throw error
    } catch is DecodingError {
      throw ChatServiceError.decoding
    } catch {
      throw ChatServiceError.transport
    }
  }

  func searchUsers(nick: String) async throws -> [ChatUser] {
    do {
      let response = try await networkManager.request(
        UserApiRouter.searchUser,
        parameters: ["nick": nick]
      )
      guard (200..<300).contains(response.statusCode) else {
        throw ChatServiceError.serverError
      }
      let dto = try decoder.decode(ChatUserSearchResponseDTO.self, from: response.data)
      return dto.data.map(\.domain)
    } catch let error as ChatServiceError {
      throw error
    } catch is DecodingError {
      throw ChatServiceError.decoding
    } catch {
      throw ChatServiceError.transport
    }
  }

  func createRoom(opponentID: String) async throws -> ChatRoom {
    do {
      let request = ChatRoomCreateRequestDTO(opponentId: opponentID)
      let response = try await networkManager.request(ChatApiRouter.createRoom, body: request)
      guard (200..<300).contains(response.statusCode) else {
        throw ChatServiceError.serverError
      }
      let dto = try decoder.decode(ChatRoomResponseDTO.self, from: response.data)
      return try dto.domain(lastSeenAt: nil)
    } catch let error as ChatServiceError {
      throw error
    } catch is DecodingError {
      throw ChatServiceError.decoding
    } catch {
      throw ChatServiceError.transport
    }
  }

  func syncMessages(roomID: String, newestLocalCreatedAt: Date?) async throws -> [ChatMessage] {
    do {
      let parameters = newestLocalCreatedAt.map { RequestQuery(["next": $0.formatted(.iso8601)]) } ?? .empty
      let response = try await networkManager.request(
        ChatApiRouter.chatList(roomID: roomID),
        parameters: parameters
      )
      guard (200..<300).contains(response.statusCode) else {
        throw ChatServiceError.serverError
      }
      let dto = try decoder.decode(ChatListResponseDTO.self, from: response.data)
      return try dto.data.map { try $0.domain() }.sorted { $0.createdAt < $1.createdAt }
    } catch let error as ChatServiceError {
      throw error
    } catch is DecodingError {
      throw ChatServiceError.decoding
    } catch {
      throw ChatServiceError.transport
    }
  }

  func uploadFiles(
    roomID: String,
    selections: [PhotoPickerUploadSelection],
    preset: ImageUploadPreset
  ) async throws -> [String] {
    do {
      let fileParts = try await imageUploadUseCase.multipartFiles(from: selections, preset: preset)
      let response = try await networkManager.request(
        ChatApiRouter.uploadFiles(roomID: roomID),
        multipartFiles: fileParts
      )
      guard (200..<300).contains(response.statusCode) else {
        throw ChatServiceError.serverError
      }
      let dto = try decoder.decode(FileResponseDTO.self, from: response.data)
      print("이미지 업로드 성공 \(dto)")
      return dto.files
    } catch let error as ChatServiceError {
      throw error
    } catch is DecodingError {
      throw ChatServiceError.decoding
    } catch is ImageCompressionError {
      throw ChatServiceError.decoding
    } catch {
      throw ChatServiceError.transport
    }
  }

  func sendMessage(roomID: String, text: String, files: [String]) async throws -> ChatMessage {
    do {
      let request = ChatSendRequestDTO(content: text, files: files.isEmpty ? nil : files)
      print(request)
      let response = try await networkManager.request(ChatApiRouter.sendChat(roomID: roomID), body: request)
      print(response)
      guard (200..<300).contains(response.statusCode) else {
        throw ChatServiceError.serverError
      }
      let dto = try decoder.decode(ChatResponseDTO.self, from: response.data)
      return try dto.domain()
    } catch let error as ChatServiceError {
      print(error)
      throw error
    } catch is DecodingError {
      throw ChatServiceError.decoding
    } catch {
      throw ChatServiceError.transport
    }
  }

  static func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }
}
