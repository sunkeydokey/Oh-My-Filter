import Foundation

nonisolated protocol MainHomeUseCase: Sendable {
  func loadTodayFilter() async throws -> MainTodayFilter
  func loadMainBanners() async throws -> [MainBanner]
  func loadHotTrendFilters() async throws -> [MainHotTrendFilter]
  func loadTodayAuthor() async throws -> MainTodayAuthor
}
