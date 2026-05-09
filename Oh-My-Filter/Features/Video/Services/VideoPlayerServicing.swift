import Foundation

nonisolated protocol VideoPlayerServicing: Sendable {
  func loadStream(videoId: String) async throws -> VideoStream
  func loadSubtitleCues(from url: URL) async throws -> [VideoSubtitleCue]
  func toggleLike(videoId: String, status: Bool) async throws -> Bool
}

nonisolated enum VideoPlayerServiceError: Error, Equatable, LocalizedError, Sendable {
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
      "영상을 찾을 수 없습니다."
    case .serverError:
      "잠시 후 다시 시도해 주세요."
    }
  }
}
