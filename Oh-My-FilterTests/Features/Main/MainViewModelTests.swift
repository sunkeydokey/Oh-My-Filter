import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct MainViewModelTests {
  @Test("load starts all section requests concurrently")
  func loadStartsAllSectionRequests() async {
    let service = ControlledMainService()
    let viewModel = MainViewModel(service: service)

    let task = Task {
      await viewModel.send(.task)
    }

    await service.waitForAllRequestsToStart()

    #expect(await service.todayFilterCallCount == 1)
    #expect(await service.mainBannersCallCount == 1)
    #expect(await service.hotTrendFiltersCallCount == 1)
    #expect(await service.todayAuthorCallCount == 1)
    #expect(viewModel.state.todayFilter == .loading(previous: nil))
    #expect(viewModel.state.mainBanners == .loading(previous: nil))
    #expect(viewModel.state.hotTrendFilters == .loading(previous: nil))
    #expect(viewModel.state.todayAuthor == .loading(previous: nil))

    await service.resumeAll()
    await task.value

    #expect(viewModel.state.todayFilter == .loaded(.todayFilter))
    #expect(viewModel.state.mainBanners == .loaded([.banner]))
    #expect(viewModel.state.hotTrendFilters == .loaded([.hotTrend]))
    #expect(viewModel.state.todayAuthor == .loaded(.todayAuthor))
  }

  @Test("partial failures preserve successful sections")
  func partialFailurePreservesSuccessfulSections() async {
    let service = ImmediateMainService(
      todayFilter: .success(.todayFilter),
      mainBanners: .failure(MainServiceError.serverError),
      hotTrendFilters: .success([.hotTrend]),
      todayAuthor: .success(.todayAuthor)
    )
    let viewModel = MainViewModel(service: service)

    await viewModel.send(.task)

    #expect(viewModel.state.todayFilter == .loaded(.todayFilter))
    #expect(viewModel.state.mainBanners == .failed(message: "잠시 후 다시 시도해 주세요.", previous: nil))
    #expect(viewModel.state.hotTrendFilters == .loaded([.hotTrend]))
    #expect(viewModel.state.todayAuthor == .loaded(.todayAuthor))
  }

  @Test("retry updates failed sections")
  func retryUpdatesFailedSections() async {
    let service = MutableMainService()
    let viewModel = MainViewModel(service: service)

    await service.configure(
      todayFilter: .success(.todayFilter),
      mainBanners: .failure(MainServiceError.serverError),
      hotTrendFilters: .success([.hotTrend]),
      todayAuthor: .success(.todayAuthor)
    )
    await viewModel.send(.task)

    #expect(viewModel.state.mainBanners == .failed(message: "잠시 후 다시 시도해 주세요.", previous: nil))

    await service.configure(
      todayFilter: .success(.todayFilter),
      mainBanners: .success([.banner]),
      hotTrendFilters: .success([.hotTrend]),
      todayAuthor: .success(.todayAuthor)
    )
    await viewModel.send(.retryMainBanners)

    #expect(viewModel.state.mainBanners == .loaded([.banner]))
  }

  @Test("retry only reloads the failed section")
  func retryOnlyReloadsFailedSection() async {
    let service = MutableMainService()
    let viewModel = MainViewModel(service: service)

    await service.configure(
      todayFilter: .success(.todayFilter),
      mainBanners: .failure(MainServiceError.serverError),
      hotTrendFilters: .success([.hotTrend]),
      todayAuthor: .success(.todayAuthor)
    )
    await viewModel.send(.task)

    #expect(await service.todayFilterCallCount == 1)
    #expect(await service.mainBannersCallCount == 1)
    #expect(await service.hotTrendFiltersCallCount == 1)
    #expect(await service.todayAuthorCallCount == 1)

    await service.configure(
      todayFilter: .success(.todayFilter),
      mainBanners: .success([.banner]),
      hotTrendFilters: .success([.hotTrend]),
      todayAuthor: .success(.todayAuthor)
    )
    await viewModel.send(.retryMainBanners)

    #expect(await service.todayFilterCallCount == 1)
    #expect(await service.mainBannersCallCount == 2)
    #expect(await service.hotTrendFiltersCallCount == 1)
    #expect(await service.todayAuthorCallCount == 1)
    #expect(viewModel.state.mainBanners == .loaded([.banner]))
  }

  @Test("retry failure keeps previous value in failed state")
  func retryFailureKeepsPreviousValueInFailedState() async {
    let service = MutableMainService()
    let viewModel = MainViewModel(service: service)

    await service.configure(
      todayFilter: .success(.todayFilter),
      mainBanners: .success([.banner]),
      hotTrendFilters: .success([.hotTrend]),
      todayAuthor: .success(.todayAuthor)
    )
    await viewModel.send(.task)

    await service.configure(
      todayFilter: .success(.todayFilter),
      mainBanners: .failure(MainServiceError.transport),
      hotTrendFilters: .success([.hotTrend]),
      todayAuthor: .success(.todayAuthor)
    )
    await viewModel.send(.retryMainBanners)

    #expect(viewModel.state.mainBanners == .failed(message: "네트워크 상태를 확인한 뒤 다시 시도해 주세요.", previous: [.banner]))
    #expect(viewModel.state.todayFilter == .loaded(.todayFilter))
    #expect(viewModel.state.hotTrendFilters == .loaded([.hotTrend]))
    #expect(viewModel.state.todayAuthor == .loaded(.todayAuthor))
  }

  @Test("cancellation does not transition to failed")
  func cancellationDoesNotTransitionToFailed() async {
    let service = ImmediateMainService(
      todayFilter: .failure(CancellationError()),
      mainBanners: .success([.banner]),
      hotTrendFilters: .success([.hotTrend]),
      todayAuthor: .success(.todayAuthor)
    )
    let viewModel = MainViewModel(service: service)

    await viewModel.send(.retryTodayFilter)

    #expect(viewModel.state.todayFilter == .idle)
  }
}

private actor ControlledMainService: MainServicing {
  private var todayFilterContinuation: CheckedContinuation<MainTodayFilter, Error>?
  private var mainBannersContinuation: CheckedContinuation<[MainBanner], Error>?
  private var hotTrendFiltersContinuation: CheckedContinuation<[MainHotTrendFilter], Error>?
  private var todayAuthorContinuation: CheckedContinuation<MainTodayAuthor, Error>?

  private(set) var todayFilterCallCount = 0
  private(set) var mainBannersCallCount = 0
  private(set) var hotTrendFiltersCallCount = 0
  private(set) var todayAuthorCallCount = 0

  func loadTodayFilter() async throws -> MainTodayFilter {
    todayFilterCallCount += 1
    return try await withCheckedThrowingContinuation { continuation in
      todayFilterContinuation = continuation
    }
  }

  func loadMainBanners() async throws -> [MainBanner] {
    mainBannersCallCount += 1
    return try await withCheckedThrowingContinuation { continuation in
      mainBannersContinuation = continuation
    }
  }

  func loadHotTrendFilters() async throws -> [MainHotTrendFilter] {
    hotTrendFiltersCallCount += 1
    return try await withCheckedThrowingContinuation { continuation in
      hotTrendFiltersContinuation = continuation
    }
  }

  func loadTodayAuthor() async throws -> MainTodayAuthor {
    todayAuthorCallCount += 1
    return try await withCheckedThrowingContinuation { continuation in
      todayAuthorContinuation = continuation
    }
  }

  func resumeAll() {
    todayFilterContinuation?.resume(returning: .todayFilter)
    mainBannersContinuation?.resume(returning: [.banner])
    hotTrendFiltersContinuation?.resume(returning: [.hotTrend])
    todayAuthorContinuation?.resume(returning: .todayAuthor)
  }

  func waitForAllRequestsToStart() async {
    let deadline = ContinuousClock.now + .seconds(1)
    while ContinuousClock.now < deadline {
      if todayFilterCallCount == 1,
         mainBannersCallCount == 1,
         hotTrendFiltersCallCount == 1,
         todayAuthorCallCount == 1 {
        return
      }

      try? await Task.sleep(for: .milliseconds(10))
    }
  }
}

private actor ImmediateMainService: MainServicing {
  let todayFilter: Result<MainTodayFilter, Error>
  let mainBanners: Result<[MainBanner], Error>
  let hotTrendFilters: Result<[MainHotTrendFilter], Error>
  let todayAuthor: Result<MainTodayAuthor, Error>

  init(
    todayFilter: Result<MainTodayFilter, Error>,
    mainBanners: Result<[MainBanner], Error>,
    hotTrendFilters: Result<[MainHotTrendFilter], Error>,
    todayAuthor: Result<MainTodayAuthor, Error>
  ) {
    self.todayFilter = todayFilter
    self.mainBanners = mainBanners
    self.hotTrendFilters = hotTrendFilters
    self.todayAuthor = todayAuthor
  }

  func loadTodayFilter() async throws -> MainTodayFilter {
    try todayFilter.get()
  }

  func loadMainBanners() async throws -> [MainBanner] {
    try mainBanners.get()
  }

  func loadHotTrendFilters() async throws -> [MainHotTrendFilter] {
    try hotTrendFilters.get()
  }

  func loadTodayAuthor() async throws -> MainTodayAuthor {
    try todayAuthor.get()
  }
}

private actor MutableMainService: MainServicing {
  private var todayFilter: Result<MainTodayFilter, Error> = .success(.todayFilter)
  private var mainBanners: Result<[MainBanner], Error> = .success([.banner])
  private var hotTrendFilters: Result<[MainHotTrendFilter], Error> = .success([.hotTrend])
  private var todayAuthor: Result<MainTodayAuthor, Error> = .success(.todayAuthor)

  private(set) var todayFilterCallCount = 0
  private(set) var mainBannersCallCount = 0
  private(set) var hotTrendFiltersCallCount = 0
  private(set) var todayAuthorCallCount = 0

  func configure(
    todayFilter: Result<MainTodayFilter, Error>,
    mainBanners: Result<[MainBanner], Error>,
    hotTrendFilters: Result<[MainHotTrendFilter], Error>,
    todayAuthor: Result<MainTodayAuthor, Error>
  ) {
    self.todayFilter = todayFilter
    self.mainBanners = mainBanners
    self.hotTrendFilters = hotTrendFilters
    self.todayAuthor = todayAuthor
  }

  func loadTodayFilter() async throws -> MainTodayFilter {
    todayFilterCallCount += 1
    return try todayFilter.get()
  }

  func loadMainBanners() async throws -> [MainBanner] {
    mainBannersCallCount += 1
    return try mainBanners.get()
  }

  func loadHotTrendFilters() async throws -> [MainHotTrendFilter] {
    hotTrendFiltersCallCount += 1
    return try hotTrendFilters.get()
  }

  func loadTodayAuthor() async throws -> MainTodayAuthor {
    todayAuthorCallCount += 1
    return try todayAuthor.get()
  }
}

private extension MainTodayFilter {
  static let todayFilter = MainTodayFilter(
    id: "today-filter",
    title: "오늘의 필터",
    subtitle: "차분한 새벽 무드",
    description: "테스트 필터 설명",
    imageUrl: URL(string: "https://example.com/today-filter.png"),
    creatorName: "새싹이",
    creatorProfileImageUrl: URL(string: "https://example.com/creator.png")
  )
}

private extension MainBanner {
  static let banner = MainBanner(
    id: "banner-1",
    title: "이번 주 추천",
    subtitle: "가장 많이 본 필터를 확인해 보세요",
    imageUrl: URL(string: "https://example.com/banner-1.png"),
    webViewURL: nil
  )
}

private extension MainHotTrendFilter {
  static let hotTrend = MainHotTrendFilter(
    id: "trend-1",
    title: "무드 보드 필터",
    imageUrl: URL(string: "https://example.com/filter-1.png"),
    creatorName: "새싹이",
    creatorProfileImageUrl: URL(string: "https://example.com/creator.png")
  )
}

private extension MainTodayAuthor {
  static let todayAuthor = MainTodayAuthor(
    userID: "author-1",
    nick: "오늘의 작가",
    name: "윤새싹",
    profileImageUrl: URL(string: "https://example.com/author.png"),
    introduction: "이번 주 가장 반응이 좋은 필터를 만든 작성자예요.",
    description: "자연의 섬세함을 담아내는 작가입니다.",
    hashTags: ["#섬세함", "#자연"],
    filters: [
      MainTodayAuthorFilter(
        id: "filter-1",
        title: "풍경 필터",
        category: "풍경",
        description: "풍경 사진을 더 멋지게!",
        imageUrl: URL(string: "https://example.com/filter.png")
      )
    ]
  )
}
