import Foundation

struct LiveCommunityFeedUseCase: CommunityFeedUseCase {
  private let service: any CommunityServicing

  init(service: any CommunityServicing) {
    self.service = service
  }

  @MainActor
  init() {
    self.init(service: LiveCommunityService())
  }

  func loadCurrentUserID() async throws -> String {
    try await service.loadCurrentUserID()
  }

  func createPost(draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    try await service.createPost(draft: draft, newImages: newImages)
  }

  func loadPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage {
    try await service.loadPosts(nextCursor: nextCursor, limit: limit, orderBy: "createdAt")
  }

  func searchPosts(title: String) async throws -> [CommunityPost] {
    try await service.searchPosts(title: title)
  }

  func loadLikedPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage {
    try await service.loadLikedPosts(nextCursor: nextCursor, limit: limit)
  }

  func loadPostDetail(postID: String) async throws -> CommunityPost {
    try await service.loadPostDetail(postID: postID)
  }

  func updatePost(postID: String, draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    try await service.updatePost(postID: postID, draft: draft, newImages: newImages)
  }

  func deletePost(postID: String) async throws {
    try await service.deletePost(postID: postID)
  }

  func toggleLike(postID: String, status: Bool) async throws -> Bool {
    try await service.toggleLike(postID: postID, status: status)
  }

  func createComment(postID: String, parentCommentID: String?, content: String) async throws -> CommunityReply {
    try await service.createComment(postID: postID, parentCommentID: parentCommentID, content: content)
  }

  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage {
    try await service.loadVideos(nextCursor: nextCursor, limit: limit)
  }
}
