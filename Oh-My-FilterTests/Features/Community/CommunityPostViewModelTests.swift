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

  @Test("edit load pre-fills draft and detects dirty state")
  func editLoadPrefillsDraft() async {
    let useCase = StubCommunityPostUseCase(post: .postWithComment)
    let viewModel = CommunityPostViewModel(mode: .edit(postID: "post-1"), useCase: useCase)

    await viewModel.send(.task)

    #expect(viewModel.state.phase == .loaded)
    #expect(viewModel.state.draft.category == "보정")
    #expect(viewModel.state.isDirty == false)

    await viewModel.send(.titleChanged("새 제목"))
    #expect(viewModel.state.isDirty)
  }

  @Test("reply submit appends one-depth reply and expands group")
  func replySubmitAppendsReply() async {
    let useCase = StubCommunityPostUseCase(post: .postWithComment)
    let viewModel = CommunityPostViewModel(mode: .detail(postID: "post-1"), useCase: useCase)

    await viewModel.send(.task)
    await viewModel.send(.replyTapped(commentID: "comment-1"))
    await viewModel.send(.commentTextChanged("답글입니다"))
    await viewModel.send(.submitComment)

    let replies = viewModel.state.post?.comments.first?.replies ?? []
    #expect(replies.map(\.content) == ["답글입니다"])
    #expect(viewModel.state.expandedReplyCommentIDs.contains("comment-1"))
    #expect(viewModel.state.commentText.isEmpty)
  }
}

private actor StubCommunityPostUseCase: CommunityFeedUseCase {
  private let post: CommunityPost

  init(post: CommunityPost) {
    self.post = post
  }

  func loadCurrentUserID() async throws -> String {
    "user-1"
  }

  func createPost(draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    post
  }

  func loadPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage {
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
    status
  }

  func createComment(postID: String, parentCommentID: String?, content: String) async throws -> CommunityReply {
    CommunityReply(id: "reply-1", content: content, createdAt: "2024-07-21T14:00:00.000Z", creator: .creator)
  }

  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage {
    CommunityVideoPage(videos: [], nextCursor: "0")
  }
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
    imageURLs: [],
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
