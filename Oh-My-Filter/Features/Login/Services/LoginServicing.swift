import Foundation

protocol LoginServicing: Sendable {
  func login(request: LoginRequest) async throws -> LoginSession
  func loginWithKakao(request: KakaoLoginRequest) async throws -> LoginSession
}

enum LoginServiceError: Error, Equatable, LocalizedError, Sendable {
  case invalidRequest(String)
  case unauthorized(String)
  case conflict(String)
  case serverError
  case invalidResponse
  case transport

  var errorDescription: String? {
    switch self {
    case let .invalidRequest(message), let .unauthorized(message), let .conflict(message):
      message
    case .serverError:
      "잠시 후 다시 시도해 주세요."
    case .invalidResponse:
      "서버 응답을 해석할 수 없습니다."
    case .transport:
      "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
    }
  }
}
