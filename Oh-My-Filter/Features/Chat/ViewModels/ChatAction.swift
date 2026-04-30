import Foundation

enum ChatAction: Equatable, Sendable {
  case task
  case disappear
  case composerChanged(String)
  case sendTapped
  case retryPending
  case deletePending
}
