import Foundation
import SwiftData

@Model
final class ChatMessageRecord {
  var chatID: String
  var roomID: String
  var content: String
  var createdAt: Date
  var updatedAt: Date
  var senderID: String
  var senderNick: String
  var senderName: String?
  var senderIntroduction: String?
  var senderProfileImage: String?
  var senderHashTagSummary: String
  var filePathSummary: String

  init(
    chatID: String,
    roomID: String,
    content: String,
    createdAt: Date,
    updatedAt: Date,
    senderID: String,
    senderNick: String,
    senderName: String?,
    senderIntroduction: String?,
    senderProfileImage: String?,
    senderHashTags: [String],
    filePaths: [String]
  ) {
    self.chatID = chatID
    self.roomID = roomID
    self.content = content
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.senderID = senderID
    self.senderNick = senderNick
    self.senderName = senderName
    self.senderIntroduction = senderIntroduction
    self.senderProfileImage = senderProfileImage
    senderHashTagSummary = ChatRecordCoding.summary(from: senderHashTags)
    filePathSummary = ChatRecordCoding.summary(from: filePaths)
  }
}

@Model
final class ChatRoomRecord {
  var roomID: String
  var updatedAt: Date
  var participantSummary: String
  var lastLocalSeenAt: Date?

  init(
    roomID: String,
    updatedAt: Date,
    participantSummary: String,
    lastLocalSeenAt: Date? = nil
  ) {
    self.roomID = roomID
    self.updatedAt = updatedAt
    self.participantSummary = participantSummary
    self.lastLocalSeenAt = lastLocalSeenAt
  }
}

extension ChatMessageRecord {
  var domain: ChatMessage {
    ChatMessage(
      id: chatID,
      roomID: roomID,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sender: ChatUser(
        id: senderID,
        nick: senderNick,
        name: senderName,
        introduction: senderIntroduction,
        profileImage: senderProfileImage,
        hashTags: ChatRecordCoding.values(from: senderHashTagSummary)
      ),
      files: ChatRecordCoding.values(from: filePathSummary)
    )
  }
}

enum ChatRecordCoding {
  private static let separator = "\u{1E}"

  static func summary(from values: [String]) -> String {
    values
      .map { value in
        value
          .replacing(separator, with: separator + separator)
      }
      .joined(separator: separator)
  }

  static func values(from summary: String) -> [String] {
    guard summary.isEmpty == false else { return [] }

    var values: [String] = []
    var current = ""
    var index = summary.startIndex

    while index < summary.endIndex {
      let character = summary[index]
      let nextIndex = summary.index(after: index)

      if String(character) == separator {
        if nextIndex < summary.endIndex, String(summary[nextIndex]) == separator {
          current.append(character)
          index = summary.index(after: nextIndex)
        } else {
          values.append(current)
          current = ""
          index = nextIndex
        }
      } else {
        current.append(character)
        index = nextIndex
      }
    }

    values.append(current)
    return values
  }
}
