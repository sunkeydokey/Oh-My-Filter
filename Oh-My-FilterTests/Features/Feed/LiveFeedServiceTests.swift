import Foundation
import Testing
@testable import Oh_My_Filter

struct LiveFeedServiceTests {
  @Test("first request uses filters endpoint with limit and popularity order")
  func firstRequestUsesExpectedQuery() async throws {
    let manager = MockFeedNetworkManager()
    let service = LiveFeedService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.pageData(nextCursor: "next-1"), statusCode: 200))
    _ = try await service.loadFilters(nextCursor: nil, limit: 10, category: nil, sort: .popularity)

    let capturedURLs = await manager.capturedURLs
    #expect(capturedURLs == ["http://filter.sesac.kr:42598/v1/filters?limit=10&order_by=popularity"])
  }

  @Test("next page request includes next cursor")
  func nextPageRequestIncludesCursor() async throws {
    let manager = MockFeedNetworkManager()
    let service = LiveFeedService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.pageData(nextCursor: "0"), statusCode: 200))
    _ = try await service.loadFilters(nextCursor: "next-1", limit: 10, category: nil, sort: .latest)

    let capturedURLs = await manager.capturedURLs
    #expect(capturedURLs == ["http://filter.sesac.kr:42598/v1/filters?limit=10&next=next-1&order_by=latest"])
  }

  @Test("service maps 400 response to invalid request")
  func mapsBadRequest() async {
    let manager = MockFeedNetworkManager()
    let service = LiveFeedService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Data(#"{"message":"bad"}"#.utf8), statusCode: 400))

    do {
      _ = try await service.loadFilters(nextCursor: nil, limit: 10, category: nil, sort: .popularity)
      Issue.record("Expected invalid request")
    } catch let error as FeedServiceError {
      #expect(error == .invalidRequest)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test("service maps server and transport failures")
  func mapsServerAndTransportFailures() async {
    let serverManager = MockFeedNetworkManager()
    let serverService = LiveFeedService(networkManager: serverManager)
    await serverManager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 500))

    do {
      _ = try await serverService.loadFilters(nextCursor: nil, limit: 10, category: nil, sort: .popularity)
      Issue.record("Expected server error")
    } catch let error as FeedServiceError {
      #expect(error == .serverError)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }

    let transportManager = MockFeedNetworkManager()
    let transportService = LiveFeedService(networkManager: transportManager)
    await transportManager.enqueueFailure(NetworkError.transport)

    do {
      _ = try await transportService.loadFilters(nextCursor: nil, limit: 10, category: nil, sort: .popularity)
      Issue.record("Expected transport error")
    } catch let error as FeedServiceError {
      #expect(error == .transport)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

private actor MockFeedNetworkManager: AuthenticatedNetworkManaging {
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
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(capturedURL(router: router, parameters: parameters))
    return try nextResult()
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(capturedURL(router: router, parameters: parameters))
    return try nextResult()
  }

  private func capturedURL<Router: ApiRouter>(router: Router, parameters: RequestQuery) -> String {
    guard parameters.isEmpty == false,
          var components = URLComponents(string: router.url) else {
      return router.url
    }

    components.queryItems = parameters.urlQueryItems
    return components.url?.absoluteString ?? router.url
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }

    return try queuedResults.removeFirst().get()
  }
}

private extension LiveFeedServiceTests {
  static func pageData(nextCursor: String) -> Data {
    Data(
      """
      {
        "data": [
          {
            "filter_id": "filter-1",
            "category": "풍경",
            "title": "Skyline Boost",
            "description": "고층 건물과 도시 라인을 선명하게 만듭니다",
            "files": ["/data/filters/previews_original_1.jpg"],
            "creator": {
              "user_id": "user-1",
              "nick": "크레용"
            },
            "like_count": 17,
            "buyer_count": 5,
            "createdAt": "2026-02-13T15:59:21.071Z",
            "updatedAt": "2026-02-13T15:59:21.071Z"
          }
        ],
        "next_cursor": "\(nextCursor)"
      }
      """.utf8
    )
  }
}
