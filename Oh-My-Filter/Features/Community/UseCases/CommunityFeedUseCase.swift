import Foundation

nonisolated protocol CommunityFeedUseCase: Sendable {
  func loadPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage
  func searchPosts(title: String) async throws -> [CommunityPost]
  func loadLikedPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage
  func loadPostDetail(postID: String) async throws -> CommunityPost
  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage
}
