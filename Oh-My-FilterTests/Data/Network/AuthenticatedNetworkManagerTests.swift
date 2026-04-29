import Foundation
import Testing
@testable import Oh_My_Filter

struct AuthenticatedNetworkManagerTests {
  @Test("authenticated request sends coordinator access token in Authorization header")
  func requestSendsAuthorizationHeader() async throws {
    let networkManager = MockAuthenticatedBaseNetworkManager()
    let tokenRefreshCoordinator = MockTokenRefreshCoordinator(accessToken: "valid-access-token")
    await networkManager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 200))
    let manager = AuthenticatedNetworkManager(
      networkManager: networkManager,
      tokenRefreshCoordinator: tokenRefreshCoordinator
    )

    let response = try await manager.request(AuthenticatedTestRouter.profile)

    #expect(response.statusCode == 200)
    #expect(await tokenRefreshCoordinator.authorizationHeaderCallCount == 1)
    #expect(await networkManager.capturedHeaders == [["Authorization": "valid-access-token"]])
  }

  @Test("401 response clears tokens and does not retry")
  func response401ClearsTokensAndDoesNotRetry() async {
    let networkManager = MockAuthenticatedBaseNetworkManager()
    let tokenRefreshCoordinator = MockTokenRefreshCoordinator(accessToken: "valid-access-token")
    await networkManager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 401))
    let manager = AuthenticatedNetworkManager(
      networkManager: networkManager,
      tokenRefreshCoordinator: tokenRefreshCoordinator
    )

    do {
      _ = try await manager.request(AuthenticatedTestRouter.profile)
      Issue.record("Expected session expiration")
    } catch {
      #expect(error as? AuthenticatedNetworkError == .sessionExpired)
    }

    #expect(await tokenRefreshCoordinator.clearTokensCallCount == 1)
    #expect(await networkManager.requestCount == 1)
  }

  @Test("419 response clears tokens and does not retry")
  func response419ClearsTokensAndDoesNotRetry() async {
    let networkManager = MockAuthenticatedBaseNetworkManager()
    let tokenRefreshCoordinator = MockTokenRefreshCoordinator(accessToken: "valid-access-token")
    await networkManager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 419))
    let manager = AuthenticatedNetworkManager(
      networkManager: networkManager,
      tokenRefreshCoordinator: tokenRefreshCoordinator
    )

    do {
      _ = try await manager.request(AuthenticatedTestRouter.profile)
      Issue.record("Expected session expiration")
    } catch {
      #expect(error as? AuthenticatedNetworkError == .sessionExpired)
    }

    #expect(await tokenRefreshCoordinator.clearTokensCallCount == 1)
    #expect(await networkManager.requestCount == 1)
  }
}

private enum AuthenticatedTestRouter: ApiRouter {
  case profile

  var url: String {
    "https://example.com/users/me/profile"
  }

  var method: HttpMethod {
    .get
  }

  var contentType: ContentType {
    .json
  }
}

private actor MockAuthenticatedBaseNetworkManager: BaseNetworkManaging {
  private var queuedResults: [Result<NetworkResponse, Error>] = []
  private(set) var capturedHeaders: [[String: String]] = []
  private(set) var requestCount = 0

  func enqueueResponse(_ response: NetworkResponse) {
    queuedResults.append(.success(response))
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    requestCount += 1
    capturedHeaders.append(headers)
    return try nextResult()
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try await request(router, headers: headers, parameters: parameters)
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }

    return try queuedResults.removeFirst().get()
  }
}

private actor MockTokenRefreshCoordinator: TokenRefreshCoordinating {
  private let accessToken: String
  private(set) var authorizationHeaderCallCount = 0
  private(set) var clearTokensCallCount = 0

  init(accessToken: String) {
    self.accessToken = accessToken
  }

  func prepareValidTokenIfNeeded() async throws {}

  func validAccessToken() async throws -> String {
    accessToken
  }

  func authorizationHeaderValue() async throws -> String {
    authorizationHeaderCallCount += 1
    return accessToken
  }

  func forceRefresh() async throws -> StoredAuthTokens {
    StoredAuthTokens(
      accessToken: accessToken,
      refreshToken: "refresh-token",
      accessTokenExpiresAt: .distantFuture,
      refreshTokenExpiresAt: .distantFuture
    )
  }

  func clearTokens() async throws {
    clearTokensCallCount += 1
  }
}
