import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class FeedViewModel {
  private static let pageSize = 10
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "FeedViewModel"
  )

  var state = FeedState()

  private let service: any FeedServicing
  private let tokenRefreshCoordinator: (any TokenRefreshCoordinating)?

  init(
    service: any FeedServicing,
    tokenRefreshCoordinator: (any TokenRefreshCoordinating)? = nil
  ) {
    self.service = service
    self.tokenRefreshCoordinator = tokenRefreshCoordinator
  }

  convenience init() {
    self.init(
      service: LiveFeedService(),
      tokenRefreshCoordinator: AppTokenRefreshCoordinator.shared
    )
  }

  func send(_ action: FeedAction) async {
    switch action {
    case .task:
      guard state.hasLoaded == false else { return }
      await reload()
    case let .sortChanged(sort):
      guard state.sort != sort else { return }
      state.sort = sort
      await reload()
    case let .loadMoreIfNeeded(filter):
      await loadMoreIfNeeded(currentFilter: filter)
    case .retry:
      await reload()
    }
  }

  private func reload() async {
    state.isInitialLoading = true
    state.isLoadingMore = false
    state.errorMessage = nil
    state.paginationErrorMessage = nil
    state.nextCursor = nil
    state.filters = []

    do {
      try await tokenRefreshCoordinator?.prepareValidTokenIfNeeded()
      let page = try await service.loadFilters(
        nextCursor: nil,
        limit: Self.pageSize,
        category: nil,
        sort: state.sort
      )
      state.filters = page.filters
      state.nextCursor = page.nextCursor
      state.hasLoaded = true
      state.isInitialLoading = false
    } catch is CancellationError {
      state.isInitialLoading = false
    } catch {
      state.hasLoaded = true
      state.isInitialLoading = false
      state.errorMessage = Self.fallbackMessage(for: error)
      Self.logger.error("❌ [FeedViewModel] reload failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private func loadMoreIfNeeded(currentFilter: FeedFilter) async {
    guard state.canLoadMore,
          state.filters.suffix(4).contains(currentFilter),
          let nextCursor = state.nextCursor else {
      return
    }

    state.isLoadingMore = true
    state.paginationErrorMessage = nil

    do {
      let page = try await service.loadFilters(
        nextCursor: nextCursor,
        limit: Self.pageSize,
        category: nil,
        sort: state.sort
      )
      state.filters.append(contentsOf: page.filters)
      state.nextCursor = page.nextCursor
      state.isLoadingMore = false
    } catch is CancellationError {
      state.isLoadingMore = false
    } catch {
      state.isLoadingMore = false
      state.paginationErrorMessage = Self.fallbackMessage(for: error)
      Self.logger.error("❌ [FeedViewModel] load more failed error=\(String(describing: error), privacy: .public)")
    }
  }

  private static func fallbackMessage(for error: Error) -> String {
    if let serviceError = error as? FeedServiceError,
       let message = serviceError.errorDescription {
      return message
    }

    return FeedServiceError.serverError.errorDescription ?? "잠시 후 다시 시도해 주세요."
  }
}
