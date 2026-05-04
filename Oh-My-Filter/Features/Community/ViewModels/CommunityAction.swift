import Foundation

nonisolated enum CommunityAction: Sendable {
  case task
  case retry
  case selectedTabChanged(CommunityTab)
  case searchTextChanged(String)
  case submitSearch
  case clearSearch
  case scroll(CommunityScrollEvent)
  case postTapped(String)
  case videoTapped(CommunityVideo)
  case routeHandled
}

nonisolated enum CommunityScrollEvent: Sendable {
  case feedItemAppeared(CommunityFeedItem)
  case videoRailItemAppeared(CommunityVideo)
}
