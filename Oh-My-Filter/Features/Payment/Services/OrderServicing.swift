import Foundation

nonisolated protocol OrderServicing: Sendable {
  func createOrder(request: OrderCreateRequest) async throws -> CreatedOrder
}

nonisolated enum OrderServiceError: Error, Equatable, LocalizedError, Sendable {
  case invalidRequest
  case filterNotFound
  case alreadyPurchased
  case invalidResponse
  case serverError
  case transport

  var errorDescription: String? {
    switch self {
    case .invalidRequest:
      "필수값을 채워주세요."
    case .filterNotFound:
      "필터를 찾을 수 없습니다."
    case .alreadyPurchased:
      "이미 구매한 필터입니다."
    case .invalidResponse:
      "주문 정보를 해석할 수 없습니다."
    case .serverError:
      "주문을 생성할 수 없습니다. 잠시 후 다시 시도해 주세요."
    case .transport:
      "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
    }
  }
}
