import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct CommunityPostViewModelTests {
  @Test("validation is required and shown only after touch")
  func validationRequiresTouchedFields() {
    var state = CommunityPostState(mode: .create)

    #expect(state.canSubmit == false)
    #expect(state.visibleError(for: .title) == nil)

    state.touchedFields.insert(.title)
    #expect(state.visibleError(for: .title) == "제목을 입력해주세요")

    state.draft = CommunityPostDraft(category: "보정", title: "제목", content: "내용")
    #expect(state.canSubmit)
  }

  @Test("category rejects forbidden characters")
  func categoryRejectsForbiddenCharacters() {
    var state = CommunityPostState(mode: .create)
    state.draft = CommunityPostDraft(category: "보정?", title: "제목", content: "내용")
    state.touchedFields.insert(.category)

    #expect(state.canSubmit == false)
    #expect(state.visibleError(for: .category) == "사용할 수 없는 문자가 포함되어 있습니다")
  }

  @Test("text input updates synchronously")
  func textInputUpdatesSynchronously() {
    let viewModel = CommunityPostViewModel(mode: .create, service: StubCommunityPostService(post: .postWithComment))

    viewModel.updateCategory("보정")
    viewModel.updateTitle("제목")
    viewModel.updateContent("안녕하세요")
    viewModel.updateCommentText("댓글입니다")
    viewModel.markFieldFocused(.content)

    #expect(viewModel.state.draft.category == "보정")
    #expect(viewModel.state.draft.title == "제목")
    #expect(viewModel.state.draft.content == "안녕하세요")
    #expect(viewModel.state.commentText == "댓글입니다")
    #expect(viewModel.state.touchedFields.contains(.content))
  }

  @Test("create submit updates current view to detail without pushing route")
  func createSubmitUpdatesCurrentViewToDetail() async {
    let mutationStore = CommunityPostMutationStore()
    let viewModel = CommunityPostViewModel(
      mode: .create,
      service: StubCommunityPostService(post: .postWithComment),
      mutationStore: mutationStore
    )

    await viewModel.send(.categoryChanged("보정"))
    await viewModel.send(.titleChanged("제목"))
    await viewModel.send(.contentChanged("내용"))
    await viewModel.send(.submit)

    #expect(viewModel.state.mode == .detail(postID: "post-1"))
    #expect(viewModel.state.post == .postWithComment)
    #expect(viewModel.state.route == nil)
    #expect(viewModel.state.shouldDismiss == false)
    #expect(viewModel.state.selectedImages.isEmpty)
    #expect(mutationStore.pendingMutation == .created(.postWithComment))
  }

  @Test("create submit shows server validation message")
  func createSubmitShowsServerValidationMessage() async {
    let viewModel = CommunityPostViewModel(
      mode: .create,
      service: StubCommunityPostService(
        post: .postWithComment,
        createResult: .failure(CommunityServiceError.invalidRequestMessage("유효하지 않은 값 타입입니다."))
      )
    )

    await viewModel.send(.categoryChanged("보정"))
    await viewModel.send(.titleChanged("제목"))
    await viewModel.send(.contentChanged("내용"))
    await viewModel.send(.submit)

    #expect(viewModel.state.errorMessage == "유효하지 않은 값 타입입니다.")
  }

  @Test("edit load pre-fills draft and detects dirty state")
  func editLoadPrefillsDraft() async {
    let service = StubCommunityPostService(post: .postWithComment)
    let viewModel = CommunityPostViewModel(mode: .edit(postID: "post-1"), service: service)

    await viewModel.send(.task)

    #expect(viewModel.state.phase == .loaded)
    #expect(viewModel.state.draft.category == "보정")
    #expect(viewModel.state.isDirty == false)

    await viewModel.send(.titleChanged("새 제목"))
    #expect(viewModel.state.isDirty)
  }

  @Test("edit submit publishes update and dismisses")
  func editSubmitPublishesUpdate() async {
    let mutationStore = CommunityPostMutationStore()
    let service = StubCommunityPostService(post: .postWithComment)
    let viewModel = CommunityPostViewModel(
      mode: .edit(postID: "post-1"),
      service: service,
      mutationStore: mutationStore
    )

    await viewModel.send(.task)
    await viewModel.send(.titleChanged("새 제목"))
    await viewModel.send(.submit)

    #expect(mutationStore.pendingMutation == .updated(.postWithComment))
    #expect(viewModel.state.shouldDismiss)
  }

  @Test("post deletion publishes delete and dismisses")
  func postDeletionPublishesDelete() async {
    let mutationStore = CommunityPostMutationStore()
    let service = StubCommunityPostService(post: .postWithComment)
    let viewModel = CommunityPostViewModel(
      mode: .detail(postID: "post-1"),
      service: service,
      mutationStore: mutationStore
    )

    await viewModel.send(.task)
    await viewModel.send(.deleteConfirmed)

    #expect(mutationStore.pendingMutation == .deleted(postID: "post-1"))
    #expect(viewModel.state.shouldDismiss)
  }

  @Test("reply submit appends one-depth reply and expands group")
  func replySubmitAppendsReply() async {
    let service = StubCommunityPostService(post: .postWithComment)
    let viewModel = CommunityPostViewModel(mode: .detail(postID: "post-1"), service: service)

    await viewModel.send(.task)
    await viewModel.send(.replyTapped(commentID: "comment-1"))
    await viewModel.send(.commentTextChanged("답글입니다"))
    await viewModel.send(.submitComment)

    let replies = viewModel.state.post?.comments.first?.replies ?? []
    #expect(replies.map(\.content) == ["답글입니다"])
    #expect(viewModel.state.expandedReplyCommentIDs.contains("comment-1"))
    #expect(viewModel.state.commentText.isEmpty)
  }

  @Test("confirming comment deletion calls delete API and clears confirmation")
  func confirmingCommentDeletionCallsDeleteAPI() async {
    let service = StubCommunityPostService(post: .postWithComment)
    let viewModel = CommunityPostViewModel(mode: .detail(postID: "post-1"), service: service)

    await viewModel.send(.task)
    await viewModel.send(.deleteCommentTapped(commentID: "comment-1"))
    await viewModel.send(.deleteCommentConfirmed)

    #expect(await service.deletedCommentRequests == [CommunityCommentDeleteRequest(postID: "post-1", commentID: "comment-1")])
    #expect(viewModel.state.pendingDeleteCommentTarget == nil)
    #expect(viewModel.state.post?.comments.isEmpty == true)
  }

  @Test("like tap applies optimistic update and debounces final status")
  func likeTapOptimisticallyUpdatesAndDebounces() async throws {
    let service = StubCommunityPostService(post: .postWithComment)
    let viewModel = CommunityPostViewModel(
      mode: .detail(postID: "post-1"),
      service: service,
      likeDebounceDuration: .milliseconds(20)
    )

    await viewModel.send(.task)
    await viewModel.send(.likeTapped)

    #expect(viewModel.state.post?.isLiked == true)
    #expect(viewModel.state.post?.likeCount == 4)
    #expect(await service.likeStatuses.isEmpty)

    await viewModel.send(.likeTapped)

    #expect(viewModel.state.post?.isLiked == false)
    #expect(viewModel.state.post?.likeCount == 3)

    try await Task.sleep(for: .milliseconds(80))
    #expect(await service.likeStatuses == [false])
  }

  @Test("like debounce failure rolls back to pre-burst state")
  func likeDebounceFailureRollsBack() async throws {
    let service = StubCommunityPostService(
      post: .postWithComment,
      likeResults: [.failure(CommunityServiceError.serverError)]
    )
    let viewModel = CommunityPostViewModel(
      mode: .detail(postID: "post-1"),
      service: service,
      likeDebounceDuration: .milliseconds(20)
    )

    await viewModel.send(.task)
    await viewModel.send(.likeTapped)

    #expect(viewModel.state.post?.isLiked == true)
    #expect(viewModel.state.post?.likeCount == 4)

    try await Task.sleep(for: .milliseconds(80))
    #expect(viewModel.state.post?.isLiked == false)
    #expect(viewModel.state.post?.likeCount == 3)
  }
}

private actor StubCommunityPostService: CommunityServicing {
  private let post: CommunityPost
  private(set) var deletedCommentRequests: [CommunityCommentDeleteRequest] = []
  private(set) var likeStatuses: [Bool] = []
  private var createResult: Result<CommunityPost, Error>?
  private var likeResults: [Result<Bool, Error>]

  init(
    post: CommunityPost,
    createResult: Result<CommunityPost, Error>? = nil,
    likeResults: [Result<Bool, Error>] = []
  ) {
    self.post = post
    self.createResult = createResult
    self.likeResults = likeResults
  }

  func loadCurrentUserID() async throws -> String {
    "user-1"
  }

  func createPost(draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    if let createResult {
      return try createResult.get()
    }
    return post
  }

  func uploadPostFiles(selections: [PhotoPickerUploadSelection]) async throws -> [String] {
    []
  }

  func loadPosts(nextCursor: String?, limit: Int, orderBy: String) async throws -> CommunityPostPage {
    CommunityPostPage(posts: [post], nextCursor: "0")
  }

  func searchPosts(title: String) async throws -> [CommunityPost] {
    [post]
  }

  func loadLikedPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage {
    CommunityPostPage(posts: [post], nextCursor: "0")
  }

  func loadPostDetail(postID: String) async throws -> CommunityPost {
    post
  }

  func updatePost(postID: String, draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    post
  }

  func deletePost(postID: String) async throws {}

  func toggleLike(postID: String, status: Bool) async throws -> Bool {
    likeStatuses.append(status)
    guard likeResults.isEmpty == false else {
      return status
    }
    return try likeResults.removeFirst().get()
  }

  func createComment(postID: String, parentCommentID: String?, content: String) async throws -> CommunityReply {
    CommunityReply(id: "reply-1", content: content, createdAt: "2024-07-21T14:00:00.000Z", creator: .creator)
  }

  func updateComment(postID: String, commentID: String, content: String) async throws -> CommunityReply {
    CommunityReply(id: commentID, content: content, createdAt: "2024-07-21T14:00:00.000Z", creator: .creator)
  }

  func deleteComment(postID: String, commentID: String) async throws {
    deletedCommentRequests.append(CommunityCommentDeleteRequest(postID: postID, commentID: commentID))
  }

  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage {
    CommunityVideoPage(videos: [], nextCursor: "0")
  }
}

private struct CommunityCommentDeleteRequest: Equatable {
  let postID: String
  let commentID: String
}

private extension CommunityCreator {
  static let creator = CommunityCreator(
    id: "user-1",
    nick: "sesac",
    name: nil,
    profileImageURL: nil,
    introduction: nil,
    hashTags: ["#사진"]
  )
}

private extension CommunityPost {
  static let postWithComment = CommunityPost(
    id: "post-1",
    category: "보정",
    title: "제목",
    content: "내용",
    creator: .creator,
    attachments: [],
    imagePaths: ["/data/posts/image.jpg"],
    isLiked: false,
    likeCount: 3,
    comments: [
      CommunityComment(
        id: "comment-1",
        content: "댓글입니다",
        createdAt: "2024-07-21T14:00:00.000Z",
        creator: .creator,
        replies: []
      ),
    ],
    createdAt: "2024-07-21T14:00:00.000Z",
    updatedAt: "2024-07-21T14:00:00.000Z"
  )
}
