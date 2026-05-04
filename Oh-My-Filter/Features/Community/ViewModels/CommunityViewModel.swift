import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class CommunityViewModel {
  private static let pageSize = 10
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "CommunityViewModel"
  )

  var state = CommunityState()

  private let useCase: any CommunityFeedUseCase
  private let tokenRefreshCoordinator: (any TokenRefreshCoordinating)?

  init(
    useCase: any CommunityFeedUseCase,
    tokenRefreshCoordinator: (any TokenRefreshCoordinating)? = nil
  ) {
    self.useCase = useCase
    self.tokenRefreshCoordinator = tokenRefreshCoordinator
  }

  convenience init(
    service: any CommunityServicing,
    tokenRefreshCoordinator: (any TokenRefreshCoordinating)? = nil
  ) {
    self.init(
      useCase: LiveCommunityFeedUseCase(service: service),
      tokenRefreshCoordinator: tokenRefreshCoordinator
    )
  }

  convenience init() {
    self.init(
      useCase: LiveCommunityFeedUseCase(),
      tokenRefreshCoordinator: AppTokenRefreshCoordinator.shared
    )
  }

  func send(_ action: CommunityAction) async {
    switch action {
    case .task:
      guard state.hasLoaded == false else { return }
      await reload()
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
      async let postsPage = useCase.loadPosts(nextCursor: nil, limit: Self.pageSize)
      async let videosPage = useCase.loadVideos(nextCursor: nil, limit: Self.pageSize)
      let (posts, videos) = try await (postsPage, videosPage)
      state.posts = posts.posts
      state.postsNextCursor = posts.nextCursor
      state.videos = videos.videos
      state.videosNextCursor = videos.nextCursor
      state.hasLoaded = true
      updatePhaseForVisibleContent()
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
        let page = try await useCase.loadLikedPosts(nextCursor: nil, limit: Self.pageSize)
        state.likedPosts = page.posts
        state.likedPostsNextCursor = page.nextCursor
      case .videos where state.videos.isEmpty && state.videosNextCursor == nil:
        try await tokenRefreshCoordinator?.prepareValidTokenIfNeeded()
        let page = try await useCase.loadVideos(nextCursor: nil, limit: Self.pageSize)
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
      state.searchedPosts = try await useCase.searchPosts(title: query)
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
      let page = try await useCase.loadPosts(nextCursor: nextCursor, limit: Self.pageSize)
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
      let page = try await useCase.loadVideos(nextCursor: nextCursor, limit: Self.pageSize)
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
      let page = try await useCase.loadLikedPosts(nextCursor: nextCursor, limit: Self.pageSize)
      state.likedPosts.append(contentsOf: page.posts)
      state.likedPostsNextCursor = page.nextCursor
      state.isLoadingMoreLikedPosts = false
      updatePhaseForVisibleContent()
    } catch {
      state.isLoadingMoreLikedPosts = false
      state.paginationErrorMessage = Self.fallbackMessage(for: error)
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
