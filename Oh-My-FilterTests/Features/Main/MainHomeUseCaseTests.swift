import Foundation
import Testing
@testable import Oh_My_Filter

struct MainHomeUseCaseTests {
  @Test("use case forwards service success values")
  func useCaseForwardsServiceSuccessValues() async throws {
    let service = ImmediateUseCaseMainService(
      todayFilter: .success(.todayFilter),
      mainBanners: .success([.banner]),
      hotTrendFilters: .success([.hotTrend]),
      todayAuthor: .success(.todayAuthor)
    )
    let useCase = LiveMainHomeUseCase(service: service)

    let todayFilter = try await useCase.loadTodayFilter()
    let mainBanners = try await useCase.loadMainBanners()
    let hotTrendFilters = try await useCase.loadHotTrendFilters()
    let todayAuthor = try await useCase.loadTodayAuthor()

    #expect(todayFilter == .todayFilter)
    #expect(mainBanners == [.banner])
    #expect(hotTrendFilters == [.hotTrend])
    #expect(todayAuthor == .todayAuthor)
  }

  @Test("use case forwards service failures")
  func useCaseForwardsServiceFailures() async {
    let service = ImmediateUseCaseMainService(
      todayFilter: .failure(MainServiceError.transport),
      mainBanners: .failure(MainServiceError.serverError),
      hotTrendFilters: .failure(MainServiceError.invalidResponse),
      todayAuthor: .failure(MainServiceError.transport)
    )
    let useCase = LiveMainHomeUseCase(service: service)

    await expectMainServiceError(.transport) {
      try await useCase.loadTodayFilter()
    }
    await expectMainServiceError(.serverError) {
      try await useCase.loadMainBanners()
    }
    await expectMainServiceError(.invalidResponse) {
      try await useCase.loadHotTrendFilters()
    }
    await expectMainServiceError(.transport) {
      try await useCase.loadTodayAuthor()
    }
  }

  private func expectMainServiceError<T>(
    _ expectedError: MainServiceError,
    operation: () async throws -> T
  ) async {
    do {
      _ = try await operation()
      Issue.record("Expected \(expectedError)")
    } catch let error as MainServiceError {
      #expect(error == expectedError)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

private actor ImmediateUseCaseMainService: MainServicing {
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

private extension MainTodayFilter {
  static let todayFilter = MainTodayFilter(
    id: "today-filter",
    title: "오늘의 필터",
    subtitle: "차분한 새벽 무드",
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
    imageUrl: URL(string: "https://example.com/banner-1.png")
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
