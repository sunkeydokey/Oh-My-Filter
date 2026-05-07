import Foundation

nonisolated protocol ProfileServicing: Sendable {
  func loadMyProfile() async throws -> MyProfile
  func updateProfile(request: ProfileUpdateRequest) async throws -> MyProfile
  func uploadProfileImage(multipartFiles: [MultipartFilePart]) async throws -> String?
}

nonisolated protocol OrderHistoryServicing: Sendable {
  func loadOrders() async throws -> [OrderHistoryItem]
}

nonisolated enum ProfileServiceError: Error, Equatable, LocalizedError, Sendable {
  case invalidRequest
  case invalidResponse
  case uploadFailed
  case serverError
  case transport

  var errorDescription: String? {
    switch self {
    case .invalidRequest:
      "입력값을 다시 확인해 주세요."
    case .invalidResponse:
      "프로필 정보를 해석할 수 없습니다."
    case .uploadFailed:
      "프로필 이미지를 업로드할 수 없습니다."
    case .serverError:
      "프로필 정보를 처리할 수 없습니다. 잠시 후 다시 시도해 주세요."
    case .transport:
      "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
    }
  }
}

nonisolated enum OrderHistoryServiceError: Error, Equatable, LocalizedError, Sendable {
  case invalidResponse
  case serverError
  case transport

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      "주문 내역을 해석할 수 없습니다."
    case .serverError:
      "주문 내역을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요."
    case .transport:
      "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
    }
  }
}
