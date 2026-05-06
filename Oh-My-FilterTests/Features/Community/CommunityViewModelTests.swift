import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct CommunityViewModelTests {
  @Test("task transitions from loading to loaded")
  func taskTransitionsToLoaded() async {
    let useCase = ControlledCommunityUseCase()
    let viewModel = CommunityViewModel(useCase: useCase)

    let task = Task {
      await viewModel.send(.task)
    }

    await useCase.waitForPostRequestCount(1)
    #expect(viewModel.state.phase == .loading)

    await useCase.resumeNextPosts(with: CommunityPostPage(posts: [.first, .second], nextCursor: "next-post"))
    await useCase.resumeNextVideos(with: CommunityVideoPage(videos: [.first], nextCursor: "0"))
    await task.value

    #expect(viewModel.state.phase == .loaded)
    #expect(viewModel.state.posts == [.first, .second])
    #expect(viewModel.state.videos == [.first])
  }

  @Test("all tab inserts video rail after first four posts")
  func allTabInsertsVideoRailAfterFourPosts() {
    var state = CommunityState()
    state.phase = .loaded
    state.posts = [.first, .second, .third, .fourth, .fifth]
    state.videos = [.first]

    #expect(state.visibleFeedItems == [
      .post(.first),
      .post(.second),
      .post(.third),
      .post(.fourth),
      .videoRail([.first]),
      .post(.fifth),
    ])
  }

  @Test("tabs compose visible feed independently")
  func tabsComposeVisibleFeed() {
    var state = CommunityState()
    state.phase = .loaded
    state.posts = [.first]
    state.videos = [.first]
    state.likedPosts = [.second]

    state.selectedTab = .posts
    #expect(state.visibleFeedItems == [.post(.first)])

    state.selectedTab = .videos
    #expect(state.visibleFeedItems == [.video(.first)])

    state.selectedTab = .liked
    #expect(state.visibleFeedItems == [.post(.second)])
  }

  @Test("post search calls api and all tab combines searched posts with local video title filter")
  func postSearchCallsAPI() async {
    let useCase = QueueCommunityUseCase()
    await useCase.enqueuePosts(.success(CommunityPostPage(posts: [.first], nextCursor: "0")))
    await useCase.enqueueVideos(.success(CommunityVideoPage(videos: [.first], nextCursor: "0")))
    await useCase.enqueueSearch(.success([.second]))
    let viewModel = CommunityViewModel(useCase: useCase)

    await viewModel.send(.task)
    await viewModel.send(.searchTextChanged("Second"))
    await viewModel.send(.submitSearch)

    #expect(await useCase.searchTitles == ["Second"])
    #expect(viewModel.state.visibleFeedItems == [.post(.second), .videoRail([.first])])
  }

  @Test("video search uses local title filtering")
  func videoSearchUsesLocalFiltering() async {
    let useCase = QueueCommunityUseCase()
    await useCase.enqueuePosts(.success(CommunityPostPage(posts: [], nextCursor: "0")))
    await useCase.enqueueVideos(.success(CommunityVideoPage(videos: [.first, .second], nextCursor: "0")))
    let viewModel = CommunityViewModel(useCase: useCase)

    await viewModel.send(.task)
    await viewModel.send(.selectedTabChanged(.videos))
    await viewModel.send(.searchTextChanged("Second"))
    await viewModel.send(.submitSearch)

    #expect(viewModel.state.visibleFeedItems == [.video(.second)])
    #expect(await useCase.searchTitles.isEmpty)
  }

  @Test("video rail scroll appends next cursor page")
  func videoRailScrollAppendsNextCursorPage() async {
    let useCase = QueueCommunityUseCase()
    await useCase.enqueuePosts(.success(CommunityPostPage(posts: [], nextCursor: "0")))
    await useCase.enqueueVideos(.success(CommunityVideoPage(videos: [.first, .second], nextCursor: "next-video")))
    await useCase.enqueueVideos(.success(CommunityVideoPage(videos: [.third], nextCursor: "0")))
    let viewModel = CommunityViewModel(useCase: useCase)

    await viewModel.send(.task)
    await viewModel.send(.scroll(.videoRailItemAppeared(.second)))

    #expect(await useCase.videoNextCursors == [nil, "next-video"])
    #expect(viewModel.state.videos == [.first, .second, .third])
    #expect(viewModel.state.videosNextCursor == "0")
  }

  @Test("video rail scroll ignores terminal cursor and search")
  func videoRailScrollIgnoresTerminalCursorAndSearch() async {
    let terminalUseCase = QueueCommunityUseCase()
    await terminalUseCase.enqueuePosts(.success(CommunityPostPage(posts: [], nextCursor: "0")))
    await terminalUseCase.enqueueVideos(.success(CommunityVideoPage(videos: [.first], nextCursor: "0")))
    let terminalViewModel = CommunityViewModel(useCase: terminalUseCase)

    await terminalViewModel.send(.task)
    await terminalViewModel.send(.scroll(.videoRailItemAppeared(.first)))

    #expect(await terminalUseCase.videoNextCursors == [nil])

    let searchingUseCase = QueueCommunityUseCase()
    await searchingUseCase.enqueuePosts(.success(CommunityPostPage(posts: [], nextCursor: "0")))
    await searchingUseCase.enqueueVideos(.success(CommunityVideoPage(videos: [.first, .second], nextCursor: "next-video")))
    let searchingViewModel = CommunityViewModel(useCase: searchingUseCase)

    await searchingViewModel.send(.task)
    await searchingViewModel.send(.searchTextChanged("First"))
    await searchingViewModel.send(.scroll(.videoRailItemAppeared(.second)))

    #expect(await searchingUseCase.videoNextCursors == [nil])
  }

  @Test("empty states distinguish search liked and content")
  func emptyStates() {
    var state = CommunityState()
    state.phase = .empty

    #expect(state.emptyStateKind == .noContent)

    state.searchText = "missing"
    #expect(state.emptyStateKind == .noSearchResults)

    state.selectedTab = .liked
    #expect(state.emptyStateKind == .noLikedPosts)
  }

  @Test("tap actions emit routes")
  func tapActionsEmitRoutes() async {
    let viewModel = CommunityViewModel(useCase: QueueCommunityUseCase())

    await viewModel.send(.postTapped("post-1"))
    #expect(viewModel.state.route == .postDetail(postID: "post-1"))

    await viewModel.send(.routeHandled)
    await viewModel.send(.videoTapped(.first))
    #expect(viewModel.state.route == .videoDetail(video: .first))

    await viewModel.send(.routeHandled)
    await viewModel.send(.createPostTapped)
    #expect(viewModel.state.route == .postCreate)
  }
}

private actor ControlledCommunityUseCase: CommunityFeedUseCase {
  private var postContinuations: [CheckedContinuation<CommunityPostPage, Error>] = []
  private var videoContinuations: [CheckedContinuation<CommunityVideoPage, Error>] = []
  private(set) var postRequestCount = 0

  func loadCurrentUserID() async throws -> String {
    "user-1"
  }

  func createPost(draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    .first
  }

  func loadPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage {
    postRequestCount += 1
    return try await withCheckedThrowingContinuation { continuation in
      postContinuations.append(continuation)
    }
  }

  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage {
    try await withCheckedThrowingContinuation { continuation in
      videoContinuations.append(continuation)
    }
  }

  func searchPosts(title: String) async throws -> [CommunityPost] {
    []
  }

  func loadLikedPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage {
    CommunityPostPage(posts: [], nextCursor: "0")
  }

  func loadPostDetail(postID: String) async throws -> CommunityPost {
    .first
  }

  func updatePost(postID: String, draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    .first
  }

  func deletePost(postID: String) async throws {}

  func toggleLike(postID: String, status: Bool) async throws -> Bool {
    status
  }

  func createComment(postID: String, parentCommentID: String?, content: String) async throws -> CommunityReply {
    CommunityReply(id: "reply-1", content: content, createdAt: "2024-07-21T14:00:00.000Z", creator: .creator)
  }

  func resumeNextPosts(with page: CommunityPostPage) {
    postContinuations.removeFirst().resume(returning: page)
  }

  func resumeNextVideos(with page: CommunityVideoPage) {
    videoContinuations.removeFirst().resume(returning: page)
  }

  func waitForPostRequestCount(_ expectedCount: Int) async {
    let deadline = ContinuousClock.now + .seconds(1)
    while ContinuousClock.now < deadline {
      if postRequestCount == expectedCount {
        return
      }

      try? await Task.sleep(for: .milliseconds(10))
    }
  }
}

private actor QueueCommunityUseCase: CommunityFeedUseCase {
  private var postResults: [Result<CommunityPostPage, Error>] = []
  private var videoResults: [Result<CommunityVideoPage, Error>] = []
  private var searchResults: [Result<[CommunityPost], Error>] = []
  private(set) var searchTitles: [String] = []
  private(set) var videoNextCursors: [String?] = []

  func loadCurrentUserID() async throws -> String {
    "user-1"
  }

  func createPost(draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    .first
  }

  func enqueuePosts(_ result: Result<CommunityPostPage, Error>) {
    postResults.append(result)
  }

  func enqueueVideos(_ result: Result<CommunityVideoPage, Error>) {
    videoResults.append(result)
  }

  func enqueueSearch(_ result: Result<[CommunityPost], Error>) {
    searchResults.append(result)
  }

  func loadPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage {
    try postResults.removeFirst().get()
  }

  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage {
    videoNextCursors.append(nextCursor)
    return try videoResults.removeFirst().get()
  }

  func searchPosts(title: String) async throws -> [CommunityPost] {
    searchTitles.append(title)
    return try searchResults.removeFirst().get()
  }

  func loadLikedPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage {
    CommunityPostPage(posts: [.second], nextCursor: "0")
  }

  func loadPostDetail(postID: String) async throws -> CommunityPost {
    .first
  }

  func updatePost(postID: String, draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    .first
  }

  func deletePost(postID: String) async throws {}

  func toggleLike(postID: String, status: Bool) async throws -> Bool {
    status
  }

  func createComment(postID: String, parentCommentID: String?, content: String) async throws -> CommunityReply {
    CommunityReply(id: "reply-1", content: content, createdAt: "2024-07-21T14:00:00.000Z", creator: .creator)
  }
}

private extension CommunityCreator {
  static let creator = CommunityCreator(
    id: "user-1",
    nick: "sesac",
    name: nil,
    profileImageURL: nil,
    introduction: nil,
    hashTags: []
  )
}

private extension CommunityPost {
  static let first = CommunityPost(
    id: "post-1",
    category: "핫스팟",
    title: "First",
    content: "First content",
    creator: .creator,
    imageURLs: [],
    imagePaths: [],
    isLiked: false,
    likeCount: 1,
    comments: [],
    createdAt: "2024-07-21T14:00:00.000Z",
    updatedAt: "2024-07-21T15:30:00.000Z"
  )

  static let second = CommunityPost(
    id: "post-2",
    category: "질문",
    title: "Second",
    content: "Second content",
    creator: .creator,
    imageURLs: [],
    imagePaths: [],
    isLiked: true,
    likeCount: 2,
    comments: [],
    createdAt: "2024-07-21T14:00:00.000Z",
    updatedAt: "2024-07-21T15:30:00.000Z"
  )

  static let third = CommunityPost(
    id: "post-3",
    category: "질문",
    title: "Third",
    content: "Third content",
    creator: .creator,
    imageURLs: [],
    imagePaths: [],
    isLiked: false,
    likeCount: 3,
    comments: [],
    createdAt: "2024-07-21T14:00:00.000Z",
    updatedAt: "2024-07-21T15:30:00.000Z"
  )

  static let fourth = CommunityPost(
    id: "post-4",
    category: "질문",
    title: "Fourth",
    content: "Fourth content",
    creator: .creator,
    imageURLs: [],
    imagePaths: [],
    isLiked: false,
    likeCount: 4,
    comments: [],
    createdAt: "2024-07-21T14:00:00.000Z",
    updatedAt: "2024-07-21T15:30:00.000Z"
  )

  static let fifth = CommunityPost(
    id: "post-5",
    category: "질문",
    title: "Fifth",
    content: "Fifth content",
    creator: .creator,
    imageURLs: [],
    imagePaths: [],
    isLiked: false,
    likeCount: 5,
    comments: [],
    createdAt: "2024-07-21T14:00:00.000Z",
    updatedAt: "2024-07-21T15:30:00.000Z"
  )
}

private extension CommunityVideo {
  static let first = CommunityVideo(
    id: "video-1",
    fileName: "video-1",
    title: "First Video",
    description: "First video description",
    duration: 120,
    thumbnailURL: nil,
    availableQualities: ["1080p"],
    viewCount: 10,
    likeCount: 1,
    isLiked: false,
    createdAt: "2024-07-21T14:00:00.000Z"
  )

  static let second = CommunityVideo(
    id: "video-2",
    fileName: "video-2",
    title: "Second Video",
    description: "Second video description",
    duration: 180,
    thumbnailURL: nil,
    availableQualities: ["720p"],
    viewCount: 20,
    likeCount: 2,
    isLiked: true,
    createdAt: "2024-07-21T14:00:00.000Z"
  )

  static let third = CommunityVideo(
    id: "video-3",
    fileName: "video-3",
    title: "Third Video",
    description: "Third video description",
    duration: 240,
    thumbnailURL: nil,
    availableQualities: ["720p"],
    viewCount: 30,
    likeCount: 3,
    isLiked: false,
    createdAt: "2024-07-21T14:00:00.000Z"
  )
}
