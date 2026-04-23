import Foundation

protocol SignupServicing: Sendable {
  func validateEmail(_ email: String) async throws -> EmailValidationStatus
  func join(request: SignupRequest) async throws
}

enum SignupServiceError: Error, Equatable, LocalizedError, Sendable {
  case invalidEmail
  case duplicateEmail
  case invalidRequest
  case serverError
  case invalidResponse
  case transport

  var errorDescription: String? {
    switch self {
    case .invalidEmail:
      "이메일 형식을 다시 확인해 주세요."
    case .duplicateEmail:
      "이미 사용 중인 이메일입니다."
    case .invalidRequest:
      "입력값을 다시 확인해 주세요."
    case .serverError:
      "잠시 후 다시 시도해 주세요."
    case .invalidResponse:
      "서버 응답을 해석할 수 없습니다."
    case .transport:
      "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
    }
  }
}
