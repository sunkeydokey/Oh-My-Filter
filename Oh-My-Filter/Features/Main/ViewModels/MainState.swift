import Foundation

nonisolated struct MainState: Equatable, Sendable {
  var todayFilter: MainSectionState<MainTodayFilter> = .idle
  var mainBanners: MainSectionState<[MainBanner]> = .idle
  var hotTrendFilters: MainSectionState<[MainHotTrendFilter]> = .idle
  var todayAuthor: MainSectionState<MainTodayAuthor> = .idle

  var isInitialLoading: Bool {
    isInitialLoading(todayFilter)
      || isInitialLoading(mainBanners)
      || isInitialLoading(hotTrendFilters)
      || isInitialLoading(todayAuthor)
  }

  private func isInitialLoading<Value: Equatable & Sendable>(_ sectionState: MainSectionState<Value>) -> Bool {
    if case .loading(previous: nil) = sectionState {
      return true
    }

    return false
  }
}
