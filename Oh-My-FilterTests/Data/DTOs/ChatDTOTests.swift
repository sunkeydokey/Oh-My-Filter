import Foundation
import Testing
@testable import Oh_My_Filter

struct ChatDTOTests {
  @Test("room create request encodes opponent id as snake case")
  func encodeRoomCreateRequest() throws {
    let request = ChatRoomCreateRequestDTO(opponentId: "65589297a93f5938a8416dc3")
    let data = try JSONEncoder().encode(request)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: String]

    #expect(object?["opponent_id"] == "65589297a93f5938a8416dc3")
    #expect(object?["opponentId"] == nil)
  }

  @Test("chat room response decodes nested participants and last chat")
  func decodeRoomResponse() throws {
    let dto = try decoder.decode(ChatRoomResponseDTO.self, from: Self.roomData)

    #expect(dto.roomId == "66387304d5418c5e1e141862")
    #expect(dto.participants.count == 1)
    #expect(dto.participants[0].userId == "6816ee1c6d1bff703149336f")
    #expect(dto.lastChat?.chatId == "66386735e7696bd61fd5ef14")
    #expect(dto.lastChat?.files.first == "/data/chats/image_1712739634962.png")
  }

  @Test("chat room response allows missing last chat")
  func decodeRoomResponseWithoutLastChat() throws {
    let dto = try decoder.decode(ChatRoomResponseDTO.self, from: Self.roomWithoutLastChatData)

    #expect(dto.roomId == "66387304d5418c5e1e141862")
    #expect(dto.lastChat == nil)
  }

  @Test("chat room list response decodes data wrapper")
  func decodeRoomListResponse() throws {
    let response = try decoder.decode(ChatRoomListResponseDTO.self, from: Self.roomListData)

    #expect(response.data.count == 1)
    #expect(response.data[0].updatedAt == "9999-05-06T06:04:52.542Z")
  }

  @Test("chat list response decodes data wrapper")
  func decodeChatListResponse() throws {
    let response = try decoder.decode(ChatListResponseDTO.self, from: Self.chatListData)

    #expect(response.data.count == 1)
    #expect(response.data[0].content == "반갑습니다 :)")
    #expect(response.data[0].sender.nick == "sesac")
  }

  @Test("socket chat response decodes minimal sender payload")
  func decodeSocketChatResponse() throws {
    let response = try decoder.decode(ChatResponseDTO.self, from: Self.socketChatData)

    #expect(response.chatId == "683c5ae31ca33ade44437e73")
    #expect(response.roomId == "68287f754b8088df94e434c1")
    #expect(response.updatedAt == response.createdAt)
    #expect(response.sender.userId == "681a28181303f718b2c0c903")
    #expect(response.sender.hashTags.isEmpty)
    #expect(response.files.count == 3)
  }

  @Test("chat file response decodes uploaded file paths")
  func decodeFileResponse() throws {
    let response = try decoder.decode(ChatFileResponseDTO.self, from: Self.fileData)

    #expect(response.files == ["/data/chats/image_1729345641848.jpg"])
  }

  @Test("send request omits files when nil")
  func encodeSendRequestWithoutFiles() throws {
    let request = ChatSendRequestDTO(content: "반갑습니다 :)")
    let data = try JSONEncoder().encode(request)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(object?["content"] as? String == "반갑습니다 :)")
    #expect(object?["files"] == nil)
  }

  private var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }
}

private extension ChatDTOTests {
  static let roomData = Data(
    """
    {
      "room_id": "66387304d5418c5e1e141862",
      "createdAt": "9999-05-06T06:04:52.542Z",
      "updatedAt": "9999-05-06T06:04:52.542Z",
      "participants": [
        {
          "user_id": "6816ee1c6d1bff703149336f",
          "nick": "sesac",
          "name": "김새싹",
          "introduction": "프로필 소개입니다.",
          "profileImage": "/data/profiles/1712739634962.png",
          "hashTags": ["#맑음"]
        }
      ],
      "lastChat": {
        "chat_id": "66386735e7696bd61fd5ef14",
        "room_id": "6638664652ba24c89bb29379",
        "content": "반갑습니다 :)",
        "createdAt": "9999-05-06T06:04:52.542Z",
        "updatedAt": "9999-05-06T06:04:52.542Z",
        "sender": {
          "user_id": "6816ee1c6d1bff703149336f",
          "nick": "sesac",
          "name": "김새싹",
          "introduction": "프로필 소개입니다.",
          "profileImage": "/data/profiles/1712739634962.png",
          "hashTags": ["#맑음"]
        },
        "files": ["/data/chats/image_1712739634962.png"]
      }
    }
    """.utf8
  )

  static let roomWithoutLastChatData = Data(
    """
    {
      "room_id": "66387304d5418c5e1e141862",
      "createdAt": "9999-05-06T06:04:52.542Z",
      "updatedAt": "9999-05-06T06:04:52.542Z",
      "participants": []
    }
    """.utf8
  )

  static let roomListData = Data(
    """
    {
      "data": [
        {
          "room_id": "66387304d5418c5e1e141862",
          "createdAt": "9999-05-06T06:04:52.542Z",
          "updatedAt": "9999-05-06T06:04:52.542Z",
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
          "chat_id": "66386735e7696bd61fd5ef14",
          "room_id": "6638664652ba24c89bb29379",
          "content": "반갑습니다 :)",
          "createdAt": "9999-05-06T06:04:52.542Z",
          "updatedAt": "9999-05-06T06:04:52.542Z",
          "sender": {
            "user_id": "6816ee1c6d1bff703149336f",
            "nick": "sesac",
            "hashTags": ["#맑음"]
          },
          "files": ["/data/chats/image_1712739634962.png"]
        }
      ]
    }
    """.utf8
  )

  static let fileData = Data(
    """
    {
      "files": ["/data/chats/image_1729345641848.jpg"]
    }
    """.utf8
  )

  static let socketChatData = Data(
    """
    {
      "chat_id": "683c5ae31ca33ade44437e73",
      "room_id": "68287f754b8088df94e434c1",
      "content": "반갑습니다 :)",
      "createdAt": "2025-06-01T13:51:31.402Z",
      "sender": {
        "user_id": "681a28181303f718b2c0c903",
        "nick": "sesac",
        "profileImage": "/data/profiles/1707716853682.png"
      },
      "files": [
        "/data/chats/image_1748785821713.jpg",
        "/data/chats/image_1748785840286.jpg",
        "/data/chats/sesac_1748785924000.pdf"
      ]
    }
    """.utf8
  )
}
