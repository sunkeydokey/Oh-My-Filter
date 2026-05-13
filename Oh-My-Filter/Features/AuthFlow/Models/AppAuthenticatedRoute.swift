import Foundation

nonisolated enum AppAuthenticatedRoute: Equatable, Sendable {
  case chatRoom(roomID: String)
  case profileEdit
}
