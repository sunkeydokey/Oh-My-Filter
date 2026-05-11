import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class CommunityViewModel {
  private static let pageSize = 10
  private static let defaultPostOrder = "createdAt"
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "CommunityViewModel"
  )

  var state = CommunityState()

  private let service: any CommunityServicing
  private let tokenRefreshCoordinator: (any TokenRefreshCoordinating)?
  private var autoRefreshTask: Task<Void, Never>?

  init(
    service: any CommunityServicing,
    tokenRefreshCoordinator: (any TokenRefreshCoordinating)? = nil
  ) {
    self.service = service
    self.tokenRefreshCoordinator = tokenRefreshCoordinator
  }

  convenience init() {
    self.init(
      service: LiveCommunityService(),
      tokenRefreshCoordinator: AppTokenRefreshCoordinator.shared
    )
  }

  func send(_ action: CommunityAction) async {
    switch action {
    case .task:
      guard state.hasLoaded == false else { return }
      await reload()
    case .refresh:
      await refetch(silent: false)
      restartAutoRefresh()
    case .autoRefresh:
      await refetch(silent: true)
    case .disappeared:
      autoRefreshTask?.cancel()
      autoRefreshTask = nil
    case .viewAppeared:
      guard state.hasLoaded else { return }
      restartAutoRefresh()
    case .retry:
      await reload()
    case let .selectedTabChanged(tab):
      guard state.selectedTab != tab else { return }
      state.selectedTab = tab
      await ensureContentForSelectedTab()
      updatePhaseForVisibleContent()
    case let .searchTextChanged(text):
      state.searchText = text
      if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        state.searchedPosts = []
        updatePhaseForVisibleContent()
      }
    case .submitSearch:
      await search()
    case .clearSearch:
      state.searchText = ""
      state.searchedPosts = []
      updatePhaseForVisibleContent()
    case let .scroll(event):
      await handleScroll(event)
    case let .postMutationReceived(mutation):
      applyPostMutation(mutation)
    case .createPostTapped:
      state.route = .postCreate
    case let .postTapped(postID):
      state.route = .postDetail(postID: postID)
    case let .videoTapped(video):
      state.route = .videoDetail(video: video)
    case .routeHandled:
      state.route = nil
    }
  }

  private func reload() async {
    state.phase = .loading
    state.errorMessage = nil
    state.paginationErrorMessage = nil
    state.postsNextCursor = nil
    state.videosNextCursor = nil
    state.likedPostsNextCursor = nil
    state.posts = []
    state.videos = []
    state.likedPosts = []
    state.searchedPosts = []

    do {
      try await tokenRefreshCoordinator?.prepareValidTokenIfNeeded()
      async let postsPage = service.loadPosts(nextCursor: nil, limit: Self.pageSize, orderBy: Self.defaultPostOrder)
      async let videosPage = service.loadVideos(nextCursor: nil, limit: Self.pageSize)
      let (posts, videos) = try await (postsPage, videosPage)
      state.posts = posts.posts
      state.postsNextCursor = posts.nextCursor
      state.videos = videos.videos
      state.videosNextCursor = videos.nextCursor
      state.hasLoaded = true
      updatePhaseForVisibleContent()
      restartAutoRefresh()
    } catch is CancellationError {
      state.phase = .loaded
    } catch {
      state.hasLoaded = true
      state.errorMessage = Self.fallbackMessage(for: error)
      state.phase = .error(message: state.errorMessage ?? "")
      Self.logger.error("❌ [CommunityViewModel] reload failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private func ensureContentForSelectedTab() async {
    guard state.hasLoaded else { return }

    do {
      switch state.selectedTab {
      case .liked where state.likedPosts.isEmpty && state.likedPostsNextCursor == nil:
        try await tokenRefreshCoordinator?.prepareValidTokenIfNeeded()
        let page = try await service.loadLikedPosts(nextCursor: nil, limit: Self.pageSize)
        state.likedPosts = page.posts
        state.likedPostsNextCursor = page.nextCursor
      case .videos where state.videos.isEmpty && state.videosNextCursor == nil:
        try await tokenRefreshCoordinator?.prepareValidTokenIfNeeded()
        let page = try await service.loadVideos(nextCursor: nil, limit: Self.pageSize)
        state.videos = page.videos
        state.videosNextCursor = page.nextCursor
      default:
        break
      }
    } catch {
      state.errorMessage = Self.fallbackMessage(for: error)
      state.phase = .error(message: state.errorMessage ?? "")
      Self.logger.error("❌ [CommunityViewModel] selected tab load failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private func search() async {
    let query = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard query.isEmpty == false else {
      state.searchedPosts = []
      updatePhaseForVisibleContent()
      return
    }

    guard state.selectedTab != .videos, state.selectedTab != .liked else {
      updatePhaseForVisibleContent()
      return
    }

    state.phase = .loading
    state.errorMessage = nil

    do {
      try await tokenRefreshCoordinator?.prepareValidTokenIfNeeded()
      state.searchedPosts = try await service.searchPosts(title: query)
      updatePhaseForVisibleContent()
    } catch is CancellationError {
      state.phase = .loaded
    } catch {
      state.errorMessage = Self.fallbackMessage(for: error)
      state.phase = .error(message: state.errorMessage ?? "")
      Self.logger.error("❌ [CommunityViewModel] search failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private func loadMoreIfNeeded(currentItem: CommunityFeedItem) async {
    switch currentItem {
    case let .post(post):
      if state.selectedTab == .liked {
        await loadMoreLikedPostsIfNeeded(currentPost: post)
      } else {
        await loadMorePostsIfNeeded(currentPost: post)
      }
    case let .video(video):
      await loadMoreVideosIfNeeded(currentVideo: video)
    case .videoRail:
      break
    }
  }

  private func handleScroll(_ event: CommunityScrollEvent) async {
    switch event {
    case let .feedItemAppeared(item):
      await loadMoreIfNeeded(currentItem: item)
    case let .videoRailItemAppeared(video):
      await loadMoreVideosIfNeeded(currentVideo: video)
    }
  }

  private func loadMorePostsIfNeeded(currentPost: CommunityPost) async {
    guard state.canLoadMorePosts,
          state.posts.suffix(4).contains(currentPost),
          let nextCursor = state.postsNextCursor else {
      return
    }

    state.isLoadingMorePosts = true
    state.paginationErrorMessage = nil

    do {
      let page = try await service.loadPosts(nextCursor: nextCursor, limit: Self.pageSize, orderBy: Self.defaultPostOrder)
      state.posts.append(contentsOf: page.posts)
      state.postsNextCursor = page.nextCursor
      state.isLoadingMorePosts = false
      updatePhaseForVisibleContent()
    } catch {
      state.isLoadingMorePosts = false
      state.paginationErrorMessage = Self.fallbackMessage(for: error)
    }
  }

  private func loadMoreVideosIfNeeded(currentVideo: CommunityVideo) async {
    guard state.canLoadMoreVideos,
          state.videos.suffix(4).contains(currentVideo),
          let nextCursor = state.videosNextCursor else {
      return
    }

    state.isLoadingMoreVideos = true
    state.paginationErrorMessage = nil

    do {
      let page = try await service.loadVideos(nextCursor: nextCursor, limit: Self.pageSize)
      state.videos.append(contentsOf: page.videos)
      state.videosNextCursor = page.nextCursor
      state.isLoadingMoreVideos = false
      updatePhaseForVisibleContent()
    } catch {
      state.isLoadingMoreVideos = false
      state.paginationErrorMessage = Self.fallbackMessage(for: error)
    }
  }

  private func loadMoreLikedPostsIfNeeded(currentPost: CommunityPost) async {
    guard state.canLoadMoreLikedPosts,
          state.likedPosts.suffix(4).contains(currentPost),
          let nextCursor = state.likedPostsNextCursor else {
      return
    }

    state.isLoadingMoreLikedPosts = true
    state.paginationErrorMessage = nil

    do {
      let page = try await service.loadLikedPosts(nextCursor: nextCursor, limit: Self.pageSize)
      state.likedPosts.append(contentsOf: page.posts)
      state.likedPostsNextCursor = page.nextCursor
      state.isLoadingMoreLikedPosts = false
      updatePhaseForVisibleContent()
    } catch {
      state.isLoadingMoreLikedPosts = false
      state.paginationErrorMessage = Self.fallbackMessage(for: error)
    }
  }

  private func applyPostMutation(_ mutation: CommunityPostMutation) {
    let searchQuery = state.searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    switch mutation {
    case let .created(post):
      upsert(post, in: &state.posts, insertIfMissing: true)

      if searchQuery.isEmpty == false, post.title.localizedStandardContains(searchQuery) {
        upsert(post, in: &state.searchedPosts, insertIfMissing: true)
      }

      if post.isLiked {
        upsert(post, in: &state.likedPosts, insertIfMissing: true)
      }
    case let .updated(post):
      upsert(post, in: &state.posts, insertIfMissing: false)
      if post.isLiked {
        upsert(post, in: &state.likedPosts, insertIfMissing: false)
      } else {
        removePost(post.id, from: &state.likedPosts)
      }

      if searchQuery.isEmpty == false, post.title.localizedStandardContains(searchQuery) {
        upsert(post, in: &state.searchedPosts, insertIfMissing: false)
      } else {
        removePost(post.id, from: &state.searchedPosts)
      }
    case let .deleted(postID):
      removePost(postID, from: &state.posts)
      removePost(postID, from: &state.likedPosts)
      removePost(postID, from: &state.searchedPosts)
    }

    updatePhaseForVisibleContent()
  }

  private func upsert(_ post: CommunityPost, in posts: inout [CommunityPost], insertIfMissing: Bool) {
    if let index = posts.firstIndex(where: { $0.id == post.id }) {
      posts[index] = post
    } else if insertIfMissing {
      posts.insert(post, at: 0)
    }
  }

  private func upsertVideo(_ video: CommunityVideo, in videos: inout [CommunityVideo]) {
    if let index = videos.firstIndex(where: { $0.id == video.id }) {
      videos[index] = video
    } else {
      videos.insert(video, at: 0)
    }
  }

  private func removePost(_ postID: String, from posts: inout [CommunityPost]) {
    posts.removeAll { $0.id == postID }
  }

  private func refetch(silent: Bool) async {
    guard state.hasLoaded else { return }

    do {
      try await tokenRefreshCoordinator?.prepareValidTokenIfNeeded()

      async let postsPage = service.loadPosts(nextCursor: nil, limit: Self.pageSize, orderBy: Self.defaultPostOrder)
      async let videosPage = service.loadVideos(nextCursor: nil, limit: Self.pageSize)
      let (posts, videos) = try await (postsPage, videosPage)

      for post in posts.posts.reversed() {
        upsert(post, in: &state.posts, insertIfMissing: true)
      }
      state.postsNextCursor = posts.nextCursor

      for video in videos.videos.reversed() {
        upsertVideo(video, in: &state.videos)
      }
      state.videosNextCursor = videos.nextCursor

      if state.selectedTab == .liked, state.likedPosts.isEmpty == false {
        let likedPage = try await service.loadLikedPosts(nextCursor: nil, limit: Self.pageSize)
        for post in likedPage.posts.reversed() {
          upsert(post, in: &state.likedPosts, insertIfMissing: true)
        }
        state.likedPostsNextCursor = likedPage.nextCursor
      }

      updatePhaseForVisibleContent()
    } catch is CancellationError {
    } catch {
      if silent == false {
        state.errorMessage = Self.fallbackMessage(for: error)
        state.phase = .error(message: state.errorMessage ?? "")
      }
      Self.logger.error("❌ [CommunityViewModel] refetch failed silent=\(silent) error=\(String(describing: error), privacy: .public)")
    }
  }

  private func restartAutoRefresh() {
    autoRefreshTask?.cancel()
    autoRefreshTask = Task { [weak self] in
      while true {
        do {
          try await Task.sleep(for: .seconds(15))
        } catch {
          return
        }
        await self?.send(.autoRefresh)
      }
    }
  }

  private func updatePhaseForVisibleContent() {
    state.phase = state.visibleFeedItems.isEmpty ? .empty : .loaded
  }

  private static func fallbackMessage(for error: Error) -> String {
    if let serviceError = error as? CommunityServiceError,
       let message = serviceError.errorDescription {
      return message
    }

    return CommunityServiceError.serverError.errorDescription ?? "잠시 후 다시 시도해 주세요."
  }
}
