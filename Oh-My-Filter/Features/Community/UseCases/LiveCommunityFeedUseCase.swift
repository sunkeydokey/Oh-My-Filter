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

  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage {
    try await service.loadVideos(nextCursor: nextCursor, limit: limit)
  }
}
