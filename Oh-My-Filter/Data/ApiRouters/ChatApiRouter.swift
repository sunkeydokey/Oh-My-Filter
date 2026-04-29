import Foundation

nonisolated enum ChatApiRouter: ApiRouter {
  case createRoom
  case roomList
  case uploadFiles(roomID: String)
  case sendChat(roomID: String)
  case chatList(roomID: String)

  var url: String {
    switch self {
    case .createRoom, .roomList:
      EndPoint.Chats.rooms
    case let .uploadFiles(roomID):
      EndPoint.Chats.files(roomID: roomID)
    case let .sendChat(roomID), let .chatList(roomID):
      EndPoint.Chats.room(roomID: roomID)
    }
  }

  var method: HttpMethod {
    switch self {
    case .createRoom, .uploadFiles, .sendChat:
      .post
    case .roomList, .chatList:
      .get
    }
  }

  var contentType: ContentType {
    switch self {
    case .uploadFiles:
      .multipart
    case .createRoom, .roomList, .sendChat, .chatList:
      .json
    }
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
