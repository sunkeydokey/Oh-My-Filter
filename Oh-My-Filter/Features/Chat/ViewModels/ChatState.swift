import Foundation

enum ChatConnectionState: Equatable, Sendable {
  case idle
  case syncing
  case connected
  case disconnected
  case connecting(attempt: Int)
  case reconnecting(attempt: Int)
  case failed(message: String)
}

struct ChatPendingMessageAlert: Equatable, Identifiable, Sendable {
  let id = UUID()
  let text: String
  let imageSelections: [PhotoPickerUploadSelection]
  let message: String
}

struct ChatState: Equatable, Sendable {
  let roomID: String
  var title: String
  var subtitle: String
  var currentUserID: String
  var messages: [ChatMessage] = []
  var composerText = ""
  var selectedImages: [PhotoPickerUploadSelection] = []
  var imageSelectionMessage: String?
  var connectionState: ChatConnectionState = .idle
  var alert: ChatPendingMessageAlert?

  var canSend: Bool {
    composerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
  }
}
