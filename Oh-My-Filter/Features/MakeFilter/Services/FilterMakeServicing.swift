import Foundation

nonisolated protocol FilterMakeServicing: Sendable {
  func uploadFiles(_ files: [MultipartFilePart]) async throws -> [String]
  func createFilter(request: FilterMakeRequest) async throws -> FilterDetail
  func updateFilter(filterID: String, request: FilterMakeRequest) async throws -> FilterDetail
}

nonisolated enum FilterMakeServiceError: LocalizedError, Equatable, Sendable {
  case invalidRequest(String)
  case filterNotFound
  case forbidden
  case invalidResponse
  case transport
  case serverError

  var errorDescription: String? {
    switch self {
    case let .invalidRequest(message):
      message
    case .filterNotFound:
      "필터를 찾을 수 없습니다."
    case .forbidden:
      "필터 수정 권한이 없습니다."
    case .invalidResponse:
      "서버 응답을 확인할 수 없습니다."
    case .transport:
      "네트워크 연결을 확인해주세요."
    case .serverError:
      "잠시 후 다시 시도해주세요."
    }
  }
}
