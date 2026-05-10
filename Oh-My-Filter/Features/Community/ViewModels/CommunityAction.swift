import Foundation

nonisolated enum CommunityAction: Sendable {
  case task
  case refresh
  case autoRefresh
  case disappeared
  case viewAppeared
  case retry
  case selectedTabChanged(CommunityTab)
  case searchTextChanged(String)
  case submitSearch
  case clearSearch
  case scroll(CommunityScrollEvent)
  case postMutationReceived(CommunityPostMutation)
  case createPostTapped
  case postTapped(String)
  case videoTapped(CommunityVideo)
  case routeHandled
}

nonisolated enum CommunityScrollEvent: Sendable {
  case feedItemAppeared(CommunityFeedItem)
  case videoRailItemAppeared(CommunityVideo)
}
