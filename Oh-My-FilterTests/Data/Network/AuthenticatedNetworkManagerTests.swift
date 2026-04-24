import Foundation
import Testing
@testable import Oh_My_Filter

struct AuthenticatedNetworkManagerTests {
  @Test("authenticated request sends access token in Authorization header")
  func requestSendsAuthorizationHeader() async throws {
    let networkManager = MockAuthenticatedBaseNetworkManager()
    let tokenStore = MockAuthenticatedTokenStore()
    await tokenStore.saveWithoutThrowing(.oldTokens)
    await networkManager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 200))
    let manager = AuthenticatedNetworkManager(
      networkManager: networkManager,
      tokenStore: tokenStore,
      authSessionRefresher: MockSessionRefresher()
    )

    let response = try await manager.request(AuthenticatedTestRouter.profile)

    #expect(response.statusCode == 200)
    #expect(await networkManager.capturedHeaders == [["Authorization": "old-access-token"]])
  }

  @Test("419 response refreshes session and retries request once")
  func response419RefreshesAndRetriesOnce() async throws {
    let networkManager = MockAuthenticatedBaseNetworkManager()
    let tokenStore = MockAuthenticatedTokenStore()
    let refresher = MockSessionRefresher()
    await tokenStore.saveWithoutThrowing(.oldTokens)
    await refresher.setResult(.success(.newTokens))
    await networkManager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 419))
    await networkManager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 200))
    let manager = AuthenticatedNetworkManager(
      networkManager: networkManager,
      tokenStore: tokenStore,
      authSessionRefresher: refresher
    )

    let response = try await manager.request(AuthenticatedTestRouter.profile)

    #expect(response.statusCode == 200)
    #expect(await refresher.refreshCount == 1)
    #expect(
      await networkManager.capturedHeaders == [
        ["Authorization": "old-access-token"],
        ["Authorization": "new-access-token"]
      ]
    )
  }

  @Test("refresh failure after 419 does not retry original request")
  func refreshFailureAfter419DoesNotRetry() async {
    let networkManager = MockAuthenticatedBaseNetworkManager()
    let tokenStore = MockAuthenticatedTokenStore()
    let refresher = MockSessionRefresher()
    await tokenStore.saveWithoutThrowing(.oldTokens)
    await refresher.setResult(.failure(AuthSessionRefreshError.expiredRefreshToken))
    await networkManager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 419))
    let manager = AuthenticatedNetworkManager(
      networkManager: networkManager,
      tokenStore: tokenStore,
      authSessionRefresher: refresher
    )

    do {
      _ = try await manager.request(AuthenticatedTestRouter.profile)
      Issue.record("Expected refresh failure")
    } catch {
      #expect(error as? AuthenticatedNetworkError == .refreshFailed)
    }

    #expect(await networkManager.requestCount == 1)
  }

  @Test("retry still returning 419 maps to authentication failure")
  func retryStillReturning419MapsToAuthenticationFailure() async {
    let networkManager = MockAuthenticatedBaseNetworkManager()
    let tokenStore = MockAuthenticatedTokenStore()
    let refresher = MockSessionRefresher()
    await tokenStore.saveWithoutThrowing(.oldTokens)
    await refresher.setResult(.success(.newTokens))
    await networkManager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 419))
    await networkManager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 419))
    let manager = AuthenticatedNetworkManager(
      networkManager: networkManager,
      tokenStore: tokenStore,
      authSessionRefresher: refresher
    )

    do {
      _ = try await manager.request(AuthenticatedTestRouter.profile)
      Issue.record("Expected refresh failure")
    } catch {
      #expect(error as? AuthenticatedNetworkError == .refreshFailed)
    }

    #expect(await networkManager.requestCount == 2)
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

private actor MockAuthenticatedTokenStore: AuthTokenStoring {
  private var storedTokens: StoredAuthTokens?

  func save(_ tokens: StoredAuthTokens) async throws {
    storedTokens = tokens
  }

  func tokens() async throws -> StoredAuthTokens? {
    storedTokens
  }

  func delete() async throws {
    storedTokens = nil
  }

  func saveWithoutThrowing(_ tokens: StoredAuthTokens) {
    storedTokens = tokens
  }
}

private actor MockSessionRefresher: AuthSessionRefreshing {
  private var result: Result<StoredAuthTokens, Error> = .success(.newTokens)
  private(set) var refreshCount = 0

  func setResult(_ result: Result<StoredAuthTokens, Error>) {
    self.result = result
  }

  func refreshSession() async throws -> StoredAuthTokens {
    refreshCount += 1
    return try result.get()
  }
}

private extension StoredAuthTokens {
  static let oldTokens = StoredAuthTokens(
    accessToken: "old-access-token",
    refreshToken: "old-refresh-token",
    accessTokenExpiresAt: Date(timeIntervalSinceReferenceDate: 1_000),
    refreshTokenExpiresAt: Date(timeIntervalSinceReferenceDate: 2_000)
  )

  static let newTokens = StoredAuthTokens(
    accessToken: "new-access-token",
    refreshToken: "new-refresh-token",
    accessTokenExpiresAt: Date(timeIntervalSinceReferenceDate: 3_000),
    refreshTokenExpiresAt: Date(timeIntervalSinceReferenceDate: 4_000)
  )
}
