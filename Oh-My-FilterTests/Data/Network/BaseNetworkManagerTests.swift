import Foundation
import Testing
@testable import Oh_My_Filter

struct BaseNetworkManagerTests {
  @Test("body request uses router metadata and encodes JSON payload")
  func requestWithBodyBuildsExpectedURLRequest() async throws {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      #expect(request.url?.absoluteString == "https://example.com/users/join")
      #expect(request.httpMethod == HttpMethod.post.rawValue)
      #expect(request.value(forHTTPHeaderField: "Content-Type") == ContentType.json.rawValue)
      #expect(request.value(forHTTPHeaderField: "Accept") == ContentType.json.rawValue)

      let body = try #require(request.httpBody)
      let payload = try JSONDecoder().decode(SignupRequest.self, from: body)
      #expect(payload == SignupRequest(email: "sesac@sesac.com", password: "1234Abcd!", nick: "새싹이"))

      return TestURLProtocol.StubResponse(statusCode: 200)
    }

    let response = try await manager.request(
      TestRouter.join,
      body: SignupRequest(email: "sesac@sesac.com", password: "1234Abcd!", nick: "새싹이")
    )

    #expect(response.statusCode == 200)
  }

  @Test("param request appends sorted query items")
  func requestWithParametersBuildsQueryString() async throws {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      #expect(request.url?.absoluteString == "https://example.com/users/search?nick=sesac&page=1")
      #expect(request.httpMethod == HttpMethod.get.rawValue)
      #expect(request.httpBody == nil)
      return TestURLProtocol.StubResponse(statusCode: 200)
    }

    let response = try await manager.request(
      TestRouter.search,
      parameters: ["page": "1", "nick": "sesac"]
    )

    #expect(response.statusCode == 200)
  }

  @Test("request applies custom headers")
  func requestAppliesCustomHeaders() async throws {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      #expect(request.value(forHTTPHeaderField: "RefreshToken") == "refresh-token")
      return TestURLProtocol.StubResponse(statusCode: 200)
    }

    let response = try await manager.request(
      TestRouter.search,
      headers: ["RefreshToken": "refresh-token"],
      parameters: .empty
    )

    #expect(response.statusCode == 200)
  }

  @Test("request injects SeSACKey and stored access token headers")
  func requestInjectsDefaultHeaders() async throws {
    let session = makeSession()
    let tokenStore = MockAuthTokenStore()
    let manager = BaseNetworkManager(session: session, tokenStore: tokenStore)
    await tokenStore.saveWithoutThrowing(.fixture)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      #expect(request.value(forHTTPHeaderField: "SeSACKey") == "test-api-key")
      #expect(request.value(forHTTPHeaderField: "Authorization") == "stored-access-token")
      return TestURLProtocol.StubResponse(statusCode: 200)
    }

    let response = try await manager.request(TestRouter.search, parameters: .empty)

    #expect(response.statusCode == 200)
  }

  @Test("home API requests include authorization headers")
  func homeApiRequestsIncludeAuthorizationHeader() async throws {
    let session = makeSession()
    let tokenStore = MockAuthTokenStore()
    let manager = BaseNetworkManager(session: session, tokenStore: tokenStore)
    await tokenStore.saveWithoutThrowing(.fixture)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      #expect(request.value(forHTTPHeaderField: "SeSACKey") == "test-api-key")
      #expect(request.value(forHTTPHeaderField: "Authorization") == "stored-access-token")
      return TestURLProtocol.StubResponse(statusCode: 200)
    }

    let response = try await manager.request(HomeApiRouter.todayFilter, parameters: .empty)

    #expect(response.statusCode == 200)
  }

  @Test("transport failures map to network transport error")
  func requestMapsTransportFailure() async {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { _ in
      throw URLError(.notConnectedToInternet)
    }

    do {
      _ = try await manager.request(TestRouter.search, parameters: .empty)
      Issue.record("Expected transport error")
    } catch let error as NetworkError {
      #expect(error == .transport)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  private func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [TestURLProtocol.self]
    return URLSession(configuration: configuration)
  }
}

private enum TestRouter: ApiRouter {
  case join
  case search

  var url: String {
    switch self {
    case .join:
      "https://example.com/users/join"
    case .search:
      "https://example.com/users/search"
    }
  }

  var method: HttpMethod {
    switch self {
    case .join:
      .post
    case .search:
      .get
    }
  }

  var contentType: ContentType {
    .json
  }
}

private actor MockAuthTokenStore: AuthTokenStoring {
  private var tokensValue: StoredAuthTokens?

  func save(_ tokens: StoredAuthTokens) async throws {
    tokensValue = tokens
  }

  func tokens() async throws -> StoredAuthTokens? {
    tokensValue
  }

  func delete() async throws {
    tokensValue = nil
  }

  func saveWithoutThrowing(_ tokens: StoredAuthTokens) {
    tokensValue = tokens
  }
}

private extension StoredAuthTokens {
  static let fixture = StoredAuthTokens(
    accessToken: "stored-access-token",
    refreshToken: "stored-refresh-token",
    accessTokenExpiresAt: Date(timeIntervalSinceReferenceDate: 1_000),
    refreshTokenExpiresAt: Date(timeIntervalSinceReferenceDate: 2_000)
  )
}
