import Foundation

nonisolated protocol FeedServicing: Sendable {
  func loadFilters(nextCursor: String?, limit: Int, category: String?, sort: FeedSort) async throws -> FeedPage
}

enum FeedServiceError: Error, Equatable, LocalizedError, Sendable {
  case invalidRequest
  case invalidResponse
  case serverError
  case transport

  var errorDescription: String? {
    switch self {
    case .invalidRequest:
      "요청 값을 확인해 주세요."
    case .invalidResponse:
      "서버 응답을 해석할 수 없습니다."
    case .serverError:
      "잠시 후 다시 시도해 주세요."
    case .transport:
      "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
    }
  }
}
