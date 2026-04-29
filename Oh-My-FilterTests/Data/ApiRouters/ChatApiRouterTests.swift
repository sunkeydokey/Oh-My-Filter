import Foundation
import Testing
@testable import Oh_My_Filter

struct ChatApiRouterTests {
  @Test("create room router uses chats collection endpoint")
  func createRoomRouter() {
    let router = ChatApiRouter.createRoom

    #expect(router.url == "http://filter.sesac.kr:42598/v1/chats")
    #expect(router.method == .post)
    #expect(router.contentType == .json)
    #expect(router.requiresAuthorizationHeader)
  }

  @Test("room list router uses chats collection endpoint")
  func roomListRouter() {
    let router = ChatApiRouter.roomList

    #expect(router.url == "http://filter.sesac.kr:42598/v1/chats")
    #expect(router.method == .get)
    #expect(router.contentType == .json)
    #expect(router.requiresAuthorizationHeader)
  }

  @Test("upload files router uses multipart room files endpoint")
  func uploadFilesRouter() {
    let router = ChatApiRouter.uploadFiles(roomID: "room-1")

    #expect(router.url == "http://filter.sesac.kr:42598/v1/chats/room-1/files")
    #expect(router.method == .post)
    #expect(router.contentType == .multipart)
    #expect(router.requiresAuthorizationHeader)
  }

  @Test("send chat router uses room endpoint")
  func sendChatRouter() {
    let router = ChatApiRouter.sendChat(roomID: "room-1")

    #expect(router.url == "http://filter.sesac.kr:42598/v1/chats/room-1")
    #expect(router.method == .post)
    #expect(router.contentType == .json)
    #expect(router.requiresAuthorizationHeader)
  }

  @Test("chat list router uses room endpoint")
  func chatListRouter() {
    let router = ChatApiRouter.chatList(roomID: "room-1")

    #expect(router.url == "http://filter.sesac.kr:42598/v1/chats/room-1")
    #expect(router.method == .get)
    #expect(router.contentType == .json)
    #expect(router.requiresAuthorizationHeader)
  }
}
