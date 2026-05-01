import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct FeedViewModelTests {
  @Test("task transitions from loading to loaded")
  func taskTransitionsToLoaded() async {
    let service = ControlledFeedService()
    let viewModel = FeedViewModel(service: service)

    let task = Task {
      await viewModel.send(.task)
    }

    await service.waitForRequestCount(1)
    #expect(viewModel.state.isInitialLoading)

    await service.resumeNext(with: FeedPage(filters: [.first], nextCursor: "next-1"))
    await task.value

    #expect(viewModel.state.isInitialLoading == false)
    #expect(viewModel.state.filters == [.first])
    #expect(viewModel.state.nextCursor == "next-1")
  }

  @Test("sort changed clears existing items and reloads with new sort")
  func sortChangedReloads() async {
    let service = QueueFeedService()
    await service.enqueue(.success(FeedPage(filters: [.first], nextCursor: "next-1")))
    await service.enqueue(.success(FeedPage(filters: [.latest], nextCursor: "0")))
    let viewModel = FeedViewModel(service: service)

    await viewModel.send(.task)
    await viewModel.send(.sortChanged(.latest))

    #expect(viewModel.state.sort == .latest)
    #expect(viewModel.state.filters == [.latest])
    #expect(await service.capturedSorts == [.popularity, .latest])
  }

  @Test("zero cursor stops additional loading")
  func zeroCursorStopsAdditionalLoading() async {
    let service = QueueFeedService()
    await service.enqueue(.success(FeedPage(filters: [.first], nextCursor: "0")))
    await service.enqueue(.success(FeedPage(filters: [.second], nextCursor: "0")))
    let viewModel = FeedViewModel(service: service)

    await viewModel.send(.task)
    await viewModel.send(.loadMoreIfNeeded(.first))

    #expect(viewModel.state.filters == [.first])
    #expect(await service.requestCount == 1)
  }

  @Test("additional load failure keeps existing items and exposes pagination error")
  func additionalLoadFailureKeepsExistingItems() async {
    let service = QueueFeedService()
    await service.enqueue(.success(FeedPage(filters: [.first, .second], nextCursor: "next-1")))
    await service.enqueue(.failure(FeedServiceError.transport))
    let viewModel = FeedViewModel(service: service)

    await viewModel.send(.task)
    await viewModel.send(.loadMoreIfNeeded(.second))

    #expect(viewModel.state.filters == [.first, .second])
    #expect(viewModel.state.paginationErrorMessage == "네트워크 상태를 확인한 뒤 다시 시도해 주세요.")
  }
}

private actor ControlledFeedService: FeedServicing {
  private var continuations: [CheckedContinuation<FeedPage, Error>] = []
  private(set) var requestCount = 0

  func loadFilters(nextCursor: String?, limit: Int, category: String?, sort: FeedSort) async throws -> FeedPage {
    requestCount += 1
    return try await withCheckedThrowingContinuation { continuation in
      continuations.append(continuation)
    }
  }

  func resumeNext(with page: FeedPage) {
    continuations.removeFirst().resume(returning: page)
  }

  func waitForRequestCount(_ expectedCount: Int) async {
    let deadline = ContinuousClock.now + .seconds(1)
    while ContinuousClock.now < deadline {
      if requestCount == expectedCount {
        return
      }

      try? await Task.sleep(for: .milliseconds(10))
    }
  }
}

private actor QueueFeedService: FeedServicing {
  private var results: [Result<FeedPage, Error>] = []
  private(set) var capturedSorts: [FeedSort] = []
  private(set) var requestCount = 0

  func enqueue(_ result: Result<FeedPage, Error>) {
    results.append(result)
  }

  func loadFilters(nextCursor: String?, limit: Int, category: String?, sort: FeedSort) async throws -> FeedPage {
    requestCount += 1
    capturedSorts.append(sort)

    guard results.isEmpty == false else {
      throw FeedServiceError.serverError
    }

    return try results.removeFirst().get()
  }
}

private extension FeedFilter {
  static let first = FeedFilter(
    id: "filter-1",
    title: "First",
    description: "First filter",
    category: "풍경",
    imageURL: URL(string: "https://example.com/1.jpg"),
    creatorNick: "크레용",
    likeCount: 3,
    buyerCount: 1,
    createdAt: "2026-02-13T15:59:21.071Z"
  )

  static let second = FeedFilter(
    id: "filter-2",
    title: "Second",
    description: "Second filter",
    category: "인물",
    imageURL: URL(string: "https://example.com/2.jpg"),
    creatorNick: "새싹",
    likeCount: 5,
    buyerCount: 2,
    createdAt: "2026-02-14T15:59:21.071Z"
  )

  static let latest = FeedFilter(
    id: "filter-latest",
    title: "Latest",
    description: "Latest filter",
    category: "야경",
    imageURL: URL(string: "https://example.com/latest.jpg"),
    creatorNick: "최신",
    likeCount: 1,
    buyerCount: 0,
    createdAt: "2026-02-15T15:59:21.071Z"
  )
}
