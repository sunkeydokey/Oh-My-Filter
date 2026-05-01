import Observation
import Foundation
import OSLog

@MainActor
@Observable
final class MainViewModel {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "MainViewModel"
  )

  var state = MainState()

  private let useCase: any MainHomeUseCase
  private let tokenRefreshCoordinator: (any TokenRefreshCoordinating)?

  init(
    useCase: any MainHomeUseCase,
    tokenRefreshCoordinator: (any TokenRefreshCoordinating)? = nil
  ) {
    self.useCase = useCase
    self.tokenRefreshCoordinator = tokenRefreshCoordinator
  }

  convenience init(
    service: any MainServicing,
    tokenRefreshCoordinator: (any TokenRefreshCoordinating)? = nil
  ) {
    self.init(
      useCase: LiveMainHomeUseCase(service: service),
      tokenRefreshCoordinator: tokenRefreshCoordinator
    )
  }

  convenience init() {
    self.init(
      useCase: LiveMainHomeUseCase(),
      tokenRefreshCoordinator: AppTokenRefreshCoordinator.shared
    )
  }

  func send(_ action: MainAction) async {
    switch action {
    case .task:
      await load()
    case .retryTodayFilter:
      await loadTodayFilter()
    case .retryMainBanners:
      await loadMainBanners()
    case .retryHotTrendFilters:
      await loadHotTrendFilters()
    case .retryTodayAuthor:
      await loadTodayAuthor()
    }
  }

  private func load() async {
    Self.logger.debug("➡️ [MainViewModel] load started")

    state.todayFilter = .loading(previous: state.todayFilter.value)
    state.mainBanners = .loading(previous: state.mainBanners.value)
    state.hotTrendFilters = .loading(previous: state.hotTrendFilters.value)
    state.todayAuthor = .loading(previous: state.todayAuthor.value)
    Self.logger.debug("➡️ [MainViewModel] states set to loading")

    do {
      try await tokenRefreshCoordinator?.prepareValidTokenIfNeeded()
    } catch is CancellationError {
      state.todayFilter = .idle
      state.mainBanners = .idle
      state.hotTrendFilters = .idle
      state.todayAuthor = .idle
      return
    } catch {
      let message = Self.fallbackMessage(for: error)
      state.todayFilter = .failed(message: message, previous: state.todayFilter.value)
      state.mainBanners = .failed(message: message, previous: state.mainBanners.value)
      state.hotTrendFilters = .failed(message: message, previous: state.hotTrendFilters.value)
      state.todayAuthor = .failed(message: message, previous: state.todayAuthor.value)
      Self.logger.error("❌ [MainViewModel] token preparation failed error=\(String(describing: error), privacy: .public)")
      return
    }

    async let todayFilterResult = loadTodayFilter()
    async let mainBannersResult = loadMainBanners()
    async let hotTrendFiltersResult = loadHotTrendFilters()
    async let todayAuthorResult = loadTodayAuthor()

    await todayFilterResult
    await mainBannersResult
    await hotTrendFiltersResult
    await todayAuthorResult
  }

  private func loadTodayFilter() async {
    let previous = state.todayFilter.value
    state.todayFilter = .loading(previous: previous)
    do {
      let todayFilter = try await useCase.loadTodayFilter()
      state.todayFilter = .loaded(todayFilter)
    } catch is CancellationError {
      state.todayFilter = previous.map { .loaded($0) } ?? .idle
    } catch {
      state.todayFilter = .failed(message: Self.fallbackMessage(for: error), previous: previous)
      let message = "❌ [MainViewModel] todayFilter failed error=\(error)"
      Self.logger.error("\(message, privacy: .public)")
    }
  }

  private func loadMainBanners() async {
    let previous = state.mainBanners.value
    state.mainBanners = .loading(previous: previous)
    do {
      let mainBanners = try await useCase.loadMainBanners()
      state.mainBanners = .loaded(mainBanners)
    } catch is CancellationError {
      state.mainBanners = previous.map { .loaded($0) } ?? .idle
    } catch {
      state.mainBanners = .failed(message: Self.fallbackMessage(for: error), previous: previous)
      let message = "❌ [MainViewModel] mainBanners failed error=\(error)"
      Self.logger.error("\(message, privacy: .public)")
    }
  }

  private func loadHotTrendFilters() async {
    let previous = state.hotTrendFilters.value
    state.hotTrendFilters = .loading(previous: previous)
    do {
      let hotTrendFilters = try await useCase.loadHotTrendFilters()
      state.hotTrendFilters = .loaded(hotTrendFilters)
    } catch is CancellationError {
      state.hotTrendFilters = previous.map { .loaded($0) } ?? .idle
    } catch {
      state.hotTrendFilters = .failed(message: Self.fallbackMessage(for: error), previous: previous)
      let message = "❌ [MainViewModel] hotTrendFilters failed error=\(error)"
      Self.logger.error("\(message, privacy: .public)")
    }
  }

  private func loadTodayAuthor() async {
    let previous = state.todayAuthor.value
    state.todayAuthor = .loading(previous: previous)
    do {
      let todayAuthor = try await useCase.loadTodayAuthor()
      state.todayAuthor = .loaded(todayAuthor)
    } catch is CancellationError {
      state.todayAuthor = previous.map { .loaded($0) } ?? .idle
    } catch {
      state.todayAuthor = .failed(message: Self.fallbackMessage(for: error), previous: previous)
      let message = "❌ [MainViewModel] todayAuthor failed error=\(error) cachedValuePresent=\(previous != nil)"
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
