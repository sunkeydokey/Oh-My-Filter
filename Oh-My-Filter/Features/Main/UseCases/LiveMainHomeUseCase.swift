import Foundation

nonisolated struct LiveMainHomeUseCase: MainHomeUseCase {
  private let service: any MainServicing

  init(service: any MainServicing) {
    self.service = service
  }

  @MainActor
  init() {
    self.init(service: LiveMainService())
  }

  func loadTodayFilter() async throws -> MainTodayFilter {
    try await service.loadTodayFilter()
  }

  func loadMainBanners() async throws -> [MainBanner] {
    try await service.loadMainBanners()
  }

  func loadHotTrendFilters() async throws -> [MainHotTrendFilter] {
    try await service.loadHotTrendFilters()
  }

  func loadTodayAuthor() async throws -> MainTodayAuthor {
    try await service.loadTodayAuthor()
  }
}
