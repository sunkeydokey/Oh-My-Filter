import Foundation

nonisolated protocol CommunityFeedUseCase: Sendable {
  func loadCurrentUserID() async throws -> String
  func createPost(draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost
  func loadPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage
  func searchPosts(title: String) async throws -> [CommunityPost]
  func loadLikedPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage
  func loadPostDetail(postID: String) async throws -> CommunityPost
  func updatePost(postID: String, draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost
  func deletePost(postID: String) async throws
  func toggleLike(postID: String, status: Bool) async throws -> Bool
  func createComment(postID: String, parentCommentID: String?, content: String) async throws -> CommunityReply
  func updateComment(postID: String, commentID: String, content: String) async throws -> CommunityReply
  func deleteComment(postID: String, commentID: String) async throws
  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage
}
