import Foundation

nonisolated protocol MainServicing: Sendable {
  func loadTodayFilter() async throws -> MainTodayFilter
  func loadMainBanners() async throws -> [MainBanner]
  func loadHotTrendFilters() async throws -> [MainHotTrendFilter]
  func loadTodayAuthor() async throws -> MainTodayAuthor
}

enum MainServiceError: Error, Equatable, LocalizedError, Sendable {
  case invalidResponse
  case serverError
  case transport

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      "서버 응답을 해석할 수 없습니다."
    case .serverError:
      "잠시 후 다시 시도해 주세요."
    case .transport:
      "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
    }
  }
}
