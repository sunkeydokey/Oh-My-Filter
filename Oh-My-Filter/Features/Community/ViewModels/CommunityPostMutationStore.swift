import Foundation
import Observation

nonisolated enum CommunityPostMutation: Equatable, Sendable {
  case created(CommunityPost)
  case updated(CommunityPost)
  case deleted(postID: String)
}

@MainActor
@Observable
final class CommunityPostMutationStore {
  var pendingMutation: CommunityPostMutation?

  func publish(_ mutation: CommunityPostMutation) {
    pendingMutation = mutation
  }

  func markHandled() {
    pendingMutation = nil
  }
}
