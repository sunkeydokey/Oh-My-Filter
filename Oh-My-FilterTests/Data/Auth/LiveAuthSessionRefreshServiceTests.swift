import Foundation
import Testing
@testable import Oh_My_Filter

struct LiveAuthSessionRefreshServiceTests {
  @Test("missing refresh token fails without request and clears store")
  func missingRefreshTokenFailsWithoutRequest() async {
    let manager = MockRefreshNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = LiveAuthSessionRefreshService(networkManager: manager, tokenStore: tokenStore)

    do {
      _ = try await service.refreshSession()
      Issue.record("Expected missing refresh token error")
    } catch {
      #expect(error as? AuthSessionRefreshError == .missingRefreshToken)
    }

    #expect(await manager.requestCount == 0)
    #expect(await tokenStore.storedTokens == nil)
  }

  @Test("expired refresh token fails without request and clears store")
  func expiredRefreshTokenFailsWithoutRequest() async {
    let manager = MockRefreshNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let now = Date(timeIntervalSinceReferenceDate: 2_000)
    await tokenStore.saveWithoutThrowing(
      StoredAuthTokens(
        accessToken: "old-access-token",
        refreshToken: "old-refresh-token",
        accessTokenExpiresAt: now.addingTimeInterval(-10),
        refreshTokenExpiresAt: now
      )
    )
    let service = LiveAuthSessionRefreshService(
      networkManager: manager,
      tokenStore: tokenStore,
      now: { now }
    )

    do {
      _ = try await service.refreshSession()
      Issue.record("Expected expired refresh token error")
    } catch {
      #expect(error as? AuthSessionRefreshError == .expiredRefreshToken)
    }

    #expect(await manager.requestCount == 0)
    #expect(await tokenStore.storedTokens == nil)
  }

  @Test("successful refresh sends RefreshToken header and stores rotated tokens")
  func successfulRefreshStoresRotatedTokens() async throws {
    let manager = MockRefreshNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    await tokenStore.saveWithoutThrowing(.oldTokens(now: now))
    await manager.enqueueResponse(
      NetworkResponse(data: Self.successData, statusCode: 200)
    )
    let service = LiveAuthSessionRefreshService(
      networkManager: manager,
      tokenStore: tokenStore,
      now: { now }
    )

    let refreshedTokens = try await service.refreshSession()

    #expect(refreshedTokens.accessToken == "new-access-token")
    #expect(refreshedTokens.refreshToken == "new-refresh-token")
    #expect(refreshedTokens.accessTokenExpiresAt == now.addingTimeInterval(120 * 60))
    #expect(refreshedTokens.refreshTokenExpiresAt == now.addingTimeInterval(12_000 * 60))
    #expect(await tokenStore.storedTokens == refreshedTokens)

    let capturedRequest = await manager.capturedRequest
    if case .refresh? = capturedRequest?.router {
      #expect(Bool(true))
    } else {
      Issue.record("Expected refresh router")
    }
    #expect(capturedRequest?.headers["RefreshToken"] == "old-refresh-token")
  }

  @Test("401 and 418 clear tokens")
  func unauthorizedAndExpiredResponsesClearTokens() async {
    for statusCode in [401, 418] {
      let manager = MockRefreshNetworkManager()
      let tokenStore = MockAuthTokenStore()
      let now = Date(timeIntervalSinceReferenceDate: 1_000)
      await tokenStore.saveWithoutThrowing(.oldTokens(now: now))
      await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: statusCode))
      let service = LiveAuthSessionRefreshService(
        networkManager: manager,
        tokenStore: tokenStore,
        now: { now }
      )

      do {
        _ = try await service.refreshSession()
        Issue.record("Expected refresh failure")
      } catch {
        if statusCode == 401 {
          #expect(error as? AuthSessionRefreshError == .unauthorizedRefreshToken)
        } else {
          #expect(error as? AuthSessionRefreshError == .expiredRefreshToken)
        }
      }

      #expect(await tokenStore.storedTokens == nil)
    }
  }

  @Test("transport failure preserves tokens")
  func transportFailurePreservesTokens() async {
    let manager = MockRefreshNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    let oldTokens = StoredAuthTokens.oldTokens(now: now)
    await tokenStore.saveWithoutThrowing(oldTokens)
    await manager.enqueueFailure(NetworkError.transport)
    let service = LiveAuthSessionRefreshService(
      networkManager: manager,
      tokenStore: tokenStore,
      now: { now }
    )

    do {
      _ = try await service.refreshSession()
      Issue.record("Expected transport error")
    } catch {
      #expect(error as? AuthSessionRefreshError == .transport)
    }

    #expect(await tokenStore.storedTokens == oldTokens)
  }
}

private actor MockRefreshNetworkManager: BaseNetworkManaging {
  struct CapturedRequest: Sendable {
    let router: AuthApiRouter
    let headers: [String: String]
  }

  private var queuedResults: [Result<NetworkResponse, Error>] = []
  private(set) var capturedRequest: CapturedRequest?
  private(set) var requestCount = 0

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
    requestCount += 1
    if let authRouter = router as? AuthApiRouter {
      capturedRequest = CapturedRequest(router: authRouter, headers: headers)
    }
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

private actor MockAuthTokenStore: AuthTokenStoring {
  private(set) var storedTokens: StoredAuthTokens?

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

private extension LiveAuthSessionRefreshServiceTests {
  static let successData = Data(
    """
    {
      "accessToken": "new-access-token",
      "refreshToken": "new-refresh-token"
    }
    """.utf8
  )
}

private extension StoredAuthTokens {
  static func oldTokens(now: Date) -> StoredAuthTokens {
    StoredAuthTokens(
      accessToken: "old-access-token",
      refreshToken: "old-refresh-token",
      accessTokenExpiresAt: now.addingTimeInterval(10),
      refreshTokenExpiresAt: now.addingTimeInterval(20)
    )
  }
}
