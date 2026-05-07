import Foundation

enum ChatAction: Equatable, Sendable {
  case task
  case disappear
  case enterForeground
  case composerChanged(String)
  case imageSelectionChanged([PhotoPickerUploadSelection])
  case removeSelectedImage(UUID)
  case sendTapped
  case retryPending
  case deletePending
}
