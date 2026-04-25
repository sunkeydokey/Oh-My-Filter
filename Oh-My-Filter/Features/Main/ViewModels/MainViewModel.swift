import Foundation
import Combine
import OSLog

@MainActor
final class MainViewModel: ObservableObject {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "MainViewModel"
  )

  @Published var todayFilterState: MainSectionLoadState = .idle
  @Published var todayFilter: MainTodayFilter?

  @Published var mainBannersState: MainSectionLoadState = .idle
  @Published var mainBanners: [MainBanner] = []

  @Published var hotTrendFiltersState: MainSectionLoadState = .idle
  @Published var hotTrendFilters: [MainHotTrendFilter] = []

  @Published var todayAuthorState: MainSectionLoadState = .idle
  @Published var todayAuthor: MainTodayAuthor?

  private let service: MainServicing

  init(service: MainServicing) {
    self.service = service
  }

  convenience init() {
    self.init(service: LiveMainService())
  }

  func load() async {
    Self.logger.debug("➡️ [MainViewModel] load started")

    todayFilterState = .loading
    mainBannersState = .loading
    hotTrendFiltersState = .loading
    todayAuthorState = .loading
    Self.logger.debug("➡️ [MainViewModel] states set to loading")

    async let todayFilterResult = loadTodayFilter()
    async let mainBannersResult = loadMainBanners()
    async let hotTrendFiltersResult = loadHotTrendFilters()
    async let todayAuthorResult = loadTodayAuthor()

    await todayFilterResult
    await mainBannersResult
    await hotTrendFiltersResult
    await todayAuthorResult

    let completionMessage = "⬅️ [MainViewModel] load finished todayFilterState=\(todayFilterState) mainBannersState=\(mainBannersState) hotTrendFiltersState=\(hotTrendFiltersState) todayAuthorState=\(todayAuthorState)"
    Self.logger.debug("\(completionMessage, privacy: .public)")
  }

  func retryTodayFilter() async {
    await loadTodayFilter()
  }

  func retryMainBanners() async {
    await loadMainBanners()
  }

  func retryHotTrendFilters() async {
    await loadHotTrendFilters()
  }

  func retryTodayAuthor() async {
    await loadTodayAuthor()
  }

  private func loadTodayFilter() async {
    todayFilterState = .loading
    do {
      let todayFilter = try await service.loadTodayFilter()
      self.todayFilter = todayFilter
      todayFilterState = .loaded
      let message = "✅ [MainViewModel] todayFilter loaded state=\(todayFilterState) id=\(todayFilter.id) title=\(todayFilter.title)"
      Self.logger.debug("\(message, privacy: .public)")
    } catch {
      if todayFilter == nil {
        todayFilterState = .failed(message: Self.fallbackMessage(for: error))
      } else {
        todayFilterState = .loaded
      }
      let message = "❌ [MainViewModel] todayFilter failed state=\(todayFilterState) error=\(error)"
      Self.logger.error("\(message, privacy: .public)")
    }
  }

  private func loadMainBanners() async {
    mainBannersState = .loading
    do {
      let mainBanners = try await service.loadMainBanners()
      self.mainBanners = mainBanners
      mainBannersState = .loaded
      let message = "✅ [MainViewModel] mainBanners loaded state=\(mainBannersState) count=\(mainBanners.count)"
      Self.logger.debug("\(message, privacy: .public)")
    } catch {
      if self.mainBanners.isEmpty {
        mainBannersState = .failed(message: Self.fallbackMessage(for: error))
      } else {
        mainBannersState = .loaded
      }
      let message = "❌ [MainViewModel] mainBanners failed state=\(mainBannersState) error=\(error)"
      Self.logger.error("\(message, privacy: .public)")
    }
  }

  private func loadHotTrendFilters() async {
    hotTrendFiltersState = .loading
    do {
      let hotTrendFilters = try await service.loadHotTrendFilters()
      self.hotTrendFilters = hotTrendFilters
      hotTrendFiltersState = .loaded
      let message = "✅ [MainViewModel] hotTrendFilters loaded state=\(hotTrendFiltersState) count=\(hotTrendFilters.count)"
      Self.logger.debug("\(message, privacy: .public)")
    } catch {
      if self.hotTrendFilters.isEmpty {
        hotTrendFiltersState = .failed(message: Self.fallbackMessage(for: error))
      } else {
        hotTrendFiltersState = .loaded
      }
      let message = "❌ [MainViewModel] hotTrendFilters failed state=\(hotTrendFiltersState) error=\(error)"
      Self.logger.error("\(message, privacy: .public)")
    }
  }

  private func loadTodayAuthor() async {
    todayAuthorState = .loading
    do {
      let todayAuthor = try await service.loadTodayAuthor()
      self.todayAuthor = todayAuthor
      todayAuthorState = .loaded
      let profileImageUrl = todayAuthor.profileImageUrl?.absoluteString ?? "<nil>"
      let introduction = todayAuthor.introduction ?? "<nil>"
      let message = "✅ [MainViewModel] todayAuthor loaded state=\(todayAuthorState) userID=\(todayAuthor.userID) nick=\(todayAuthor.nick) profileImageUrl=\(profileImageUrl) introduction=\(introduction)"
      Self.logger.debug("\(message, privacy: .public)")
    } catch {
      if todayAuthor == nil {
        todayAuthorState = .failed(message: Self.fallbackMessage(for: error))
      } else {
        todayAuthorState = .loaded
      }
      let message = "❌ [MainViewModel] todayAuthor failed state=\(todayAuthorState) error=\(error) cachedValuePresent=\(todayAuthor != nil)"
      Self.logger.error("\(message, privacy: .public)")
    }
  }

  private static func fallbackMessage(for error: Error) -> String {
    if let serviceError = error as? MainServiceError,
       let message = serviceError.errorDescription {
      return message
    }

    return MainServiceError.serverError.errorDescription ?? "잠시 후 다시 시도해 주세요."
  }
}
