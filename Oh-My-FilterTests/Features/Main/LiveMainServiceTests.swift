import Foundation
import Testing
@testable import Oh_My_Filter

struct LiveMainServiceTests {
  @Test("today filter request uses the today filter endpoint")
  func todayFilterUsesExpectedRouter() async throws {
    let manager = MockMainNetworkManager()
    let service = LiveMainService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.todayFilterData, statusCode: 200))
    _ = try await service.loadTodayFilter()

    let capturedURLs = await manager.capturedURLs
    #expect(capturedURLs == ["http://filter.sesac.kr:42598/v1/filters/today-filter"])
  }

  @Test("main banners decode an empty array response")
  func mainBannersDecodeEmptyArray() async throws {
    let manager = MockMainNetworkManager()
    let service = LiveMainService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Data(#"{"data":[]}"#.utf8), statusCode: 200))
    let banners = try await service.loadMainBanners()

    #expect(banners.isEmpty)
  }

  @Test("hot trend filters decode response payload")
  func hotTrendFiltersDecodeResponse() async throws {
    let manager = MockMainNetworkManager()
    let service = LiveMainService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.hotTrendData, statusCode: 200))
    let filters = try await service.loadHotTrendFilters()

    #expect(filters.count == 2)
    #expect(filters.first?.title == "Skyline Boost")
    #expect(filters.first?.imageUrl?.absoluteString.contains("previews_original_1770998360980.jpg") == true)
  }

  @Test("hot trend filters decode an empty array response")
  func hotTrendFiltersDecodeEmptyArray() async throws {
    let manager = MockMainNetworkManager()
    let service = LiveMainService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Data(#"{"data":[]}"#.utf8), statusCode: 200))
    let filters = try await service.loadHotTrendFilters()

    #expect(filters.isEmpty)
  }

  @Test("today author request uses the existing user router")
  func todayAuthorUsesExpectedRouter() async throws {
    let manager = MockMainNetworkManager()
    let service = LiveMainService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.todayAuthorData, statusCode: 200))
    let todayAuthor = try await service.loadTodayAuthor()

    let capturedURLs = await manager.capturedURLs
    #expect(capturedURLs == ["http://filter.sesac.kr:42598/v1/users/today-author"])
    #expect(todayAuthor.profileImageUrl?.absoluteString.contains("/v1/data/profiles/1765346492791.jpg") == true)
    #expect(todayAuthor.name == "윤새싹")
    #expect(todayAuthor.description == "윤새싹은 자연의 섬세한 아름다움을 포착하는 데 탁월한 감각을 지닌 사진작가입니다.")
    #expect(todayAuthor.filters.first?.id == "filter-1")
    #expect(todayAuthor.filters.first?.imageUrl?.absoluteString.contains("/v1/data/filters/previews_original_1729345641848.jpg") == true)
  }

  @Test("network failures map to the transport error")
  func networkFailuresMapToTransportError() async {
    let manager = MockMainNetworkManager()
    let service = LiveMainService(networkManager: manager)

    await manager.enqueueFailure(NetworkError.transport)

    do {
      _ = try await service.loadTodayFilter()
      Issue.record("Expected transport error")
    } catch let error as MainServiceError {
      #expect(error == .transport)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

private actor MockMainNetworkManager: BaseNetworkManaging {
  private var queuedResults: [Result<NetworkResponse, Error>] = []
  private(set) var capturedURLs: [String] = []

  func enqueueResponse(_ response: NetworkResponse) {
    queuedResults.append(.success(response))
  }

  func enqueueFailure(_ error: Error) {
    queuedResults.append(.failure(error))
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(router.url)
    return try nextResult()
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(router.url)
    return try nextResult()
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }

    return try queuedResults.removeFirst().get()
  }
}

private extension LiveMainServiceTests {
  static let todayFilterData = Data(
    """
    {
      "filter_id": "698f4a592d826cebc45be870",
      "category": "풍경",
      "title": "비비드 풍경 필터",
      "introduction": "새싹을 담은 필터",
      "description": "햇살 아래 돋아나는 새싹처럼, 맑고 투명한 빛을 담은 자연 감성 필터입니다. 너무 과하지 않게, 부드러운 색감으로 분위기를 살려줍니다. 새로운 시작, 순수한 감정을 담고 싶을 때 이 피어를 사용해보세요.",
      "files": [
        "/data/filters/filter_original_1770998360980.jpg",
        "/data/filters/filter_filtered_1770998361013.jpg"
      ],
      "creator": {
        "user_id": "698f49392d826cebc45be72f",
        "nick": "크레용",
        "name": "김민준",
        "introduction": "안녕하세요! 크레용입니다!",
        "profileImage": "/data/profiles/1770998531417.jpg",
        "hashTags": ["밝음", "긍정적"]
      },
      "like_count": 0,
      "buyer_count": 0,
      "createdAt": "2026-02-08T14:55:45.508Z",
      "updatedAt": "2026-02-08T14:55:45.508Z"
    }
    """.utf8
  )

  static let hotTrendData = Data(
    """
    {
      "data": [
        {
          "filter_id": "698f4a592d826cebc45be870",
          "category": "풍경",
          "title": "Skyline Boost",
          "description": "고층 건물과 도시 라인을 선명하게 만듭니다",
          "files": [
            "/data/filters/previews_original_1770998360980.jpg",
            "/data/filters/previews_filtered_1770998361013.jpg"
          ],
          "creator": {
            "user_id": "698f49392d826cebc45be72f",
            "nick": "크레용",
            "name": "김민준",
            "introduction": "안녕하세요! 크레용입니다!",
            "profileImage": "/data/profiles/1770998531417.jpg",
            "hashTags": ["밝음", "긍정적"]
          },
          "is_liked": false,
          "like_count": 0,
          "buyer_count": 0,
          "createdAt": "2026-02-13T15:59:21.071Z",
          "updatedAt": "2026-02-13T15:59:21.071Z"
        },
        {
          "filter_id": "695761def1736c2b36c4e398",
          "category": "푸드",
          "title": "여름 안에서",
          "description": "무더운 여름, 카페에 앉아 시원한 음료 한 잔",
          "files": [
            "/data/filters/filter_original_1767334366912.jpg",
            "/data/filters/filter_filtered_1767334366946.jpg"
          ],
          "creator": {
            "user_id": "693f98ccc06140e4f9c4f28f",
            "nick": "andev",
            "name": "안대현",
            "introduction": "필터 만드는 개발자 andev 입니다.",
            "profileImage": "/data/profiles/1767519161456.jpg",
            "hashTags": ["포근함", "따뜻함"]
          },
          "is_liked": false,
          "like_count": 0,
          "buyer_count": 0,
          "createdAt": "2026-01-02T06:12:46.995Z",
          "updatedAt": "2026-01-28T08:40:30.065Z"
        }
      ]
    }
    """.utf8
  )

  static let todayAuthorData = Data(
    """
    {
      "author": {
        "user_id": "author-1",
        "nick": "SESAC YOON",
        "name": "윤새싹",
        "profileImage": "/data/profiles/1765346492791.jpg",
        "hashTags": ["#섬세함", "#자연", "#미니멀"],
        "introduction": "자연의 섬세함을 담아내는 감성 사진작가",
        "description": "윤새싹은 자연의 섬세한 아름다움을 포착하는 데 탁월한 감각을 지닌 사진작가입니다."
      },
      "filters": [
        {
          "filter_id": "filter-1",
          "category": "풍경",
          "title": "풍경 필터",
          "description": "풍경 사진을 더 멋지게!",
          "files": [
            "/data/filters/previews_original_1729345641848.jpg",
            "/data/filters/previews_filtered_1729345641849.jpg"
          ],
          "creator": {
            "user_id": "author-1",
            "nick": "SESAC YOON",
            "name": "윤새싹",
            "introduction": "자연의 섬세함을 담아내는 감성 사진작가",
            "profileImage": "/data/profiles/1765346492791.jpg",
            "hashTags": ["#섬세함"]
          },
          "is_liked": false,
          "like_count": 15,
          "buyer_count": 3,
          "createdAt": "2026-02-13T15:59:21.071Z",
          "updatedAt": "2026-02-13T15:59:21.071Z"
        }
      ]
    }
    """.utf8
  )
}
