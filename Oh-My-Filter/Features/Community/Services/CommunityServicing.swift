import Foundation

nonisolated protocol CommunityServicing: Sendable {
  func loadPosts(nextCursor: String?, limit: Int, orderBy: String) async throws -> CommunityPostPage
  func searchPosts(title: String) async throws -> [CommunityPost]
  func loadLikedPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage
  func loadPostDetail(postID: String) async throws -> CommunityPost
  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage
}

nonisolated enum CommunityServiceError: Error, Equatable, LocalizedError, Sendable {
  case invalidRequest
  case invalidResponse
  case transport
  case notFound
  case serverError

  var errorDescription: String? {
    switch self {
    case .invalidRequest:
      "요청 값을 확인해 주세요."
    case .invalidResponse:
      "응답을 읽을 수 없습니다."
    case .transport:
      "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
    case .notFound:
      "콘텐츠를 찾을 수 없습니다."
    case .serverError:
      "잠시 후 다시 시도해 주세요."
    }
  }
}
