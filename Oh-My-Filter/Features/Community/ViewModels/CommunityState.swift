import Foundation

nonisolated struct CommunityState: Equatable, Sendable {
  var selectedTab: CommunityTab = .all
  var searchText = ""
  var phase: CommunityLoadPhase = .initial
  var posts: [CommunityPost] = []
  var videos: [CommunityVideo] = []
  var likedPosts: [CommunityPost] = []
  var searchedPosts: [CommunityPost] = []
  var postsNextCursor: String?
  var videosNextCursor: String?
  var likedPostsNextCursor: String?
  var isLoadingMorePosts = false
  var isLoadingMoreVideos = false
  var isLoadingMoreLikedPosts = false
  var errorMessage: String?
  var paginationErrorMessage: String?
  var route: CommunityRoute?
  var hasLoaded = false

  var isSearching: Bool {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
  }

  var visibleFeedItems: [CommunityFeedItem] {
    switch selectedTab {
    case .all:
      let sourcePosts = isSearching ? searchedPosts : posts
      let postItems = sourcePosts.map(CommunityFeedItem.post)
      guard videos.isEmpty == false else { return postItems }

      var items = Array(postItems.prefix(4))
      items.append(.videoRail(videos))
      items.append(contentsOf: postItems.dropFirst(4))
      return items
    case .posts:
      return (isSearching ? searchedPosts : posts).map(CommunityFeedItem.post)
    case .videos:
      let sourceVideos = isSearching
        ? videos.filter { $0.title.localizedStandardContains(searchText) }
        : videos
      return sourceVideos.map(CommunityFeedItem.video)
    case .liked:
      return likedPosts.map(CommunityFeedItem.post)
    }
  }

  var emptyStateKind: CommunityEmptyStateKind? {
    guard phase == .empty || (phase == .loaded && visibleFeedItems.isEmpty) else {
      return nil
    }

    if selectedTab == .liked {
      return .noLikedPosts
    }

    if isSearching {
      return .noSearchResults
    }

    return .noContent
  }

  var canLoadMorePosts: Bool {
    hasLoaded && isSearching == false && isLoadingMorePosts == false && postsNextCursor != nil && postsNextCursor != "0"
  }

  var canLoadMoreVideos: Bool {
    hasLoaded && isSearching == false && isLoadingMoreVideos == false && videosNextCursor != nil && videosNextCursor != "0"
  }

  var canLoadMoreLikedPosts: Bool {
    hasLoaded && isLoadingMoreLikedPosts == false && likedPostsNextCursor != nil && likedPostsNextCursor != "0"
  }
}
