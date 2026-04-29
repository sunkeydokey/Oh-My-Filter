import Foundation
import Testing
@testable import Oh_My_Filter

struct TokenRefreshCoordinatorTests {
  @Test("access token with less than 90 seconds remaining refreshes")
  func nearExpiryAccessTokenRefreshes() async throws {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    let tokenStore = MockCoordinatorTokenStore(tokens: .oldTokens(now: now, accessTokenLifetime: 89))
    let refresher = MockCoordinatorSessionRefresher(result: .success(.newTokens(now: now)))
    let coordinator = TokenRefreshCoordinator(
      tokenStore: tokenStore,
      authSessionRefresher: refresher,
      now: { now }
    )

    let accessToken = try await coordinator.validAccessToken()

    #expect(accessToken == "new-access-token")
    #expect(await refresher.refreshCount == 1)
  }

  @Test("access token with at least 90 seconds remaining uses current token")
  func validAccessTokenUsesCurrentToken() async throws {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    let tokenStore = MockCoordinatorTokenStore(tokens: .oldTokens(now: now, accessTokenLifetime: 90))
    let refresher = MockCoordinatorSessionRefresher(result: .success(.newTokens(now: now)))
    let coordinator = TokenRefreshCoordinator(
      tokenStore: tokenStore,
      authSessionRefresher: refresher,
      now: { now }
    )

    let accessToken = try await coordinator.validAccessToken()

    #expect(accessToken == "old-access-token")
    #expect(await refresher.refreshCount == 0)
  }

  @Test("concurrent near-expiry calls share one refresh")
  func concurrentNearExpiryCallsShareOneRefresh() async throws {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    let tokenStore = MockCoordinatorTokenStore(tokens: .oldTokens(now: now, accessTokenLifetime: 10))
    let refresher = MockCoordinatorSessionRefresher(
      result: .success(.newTokens(now: now)),
      delay: .milliseconds(100)
    )
    let coordinator = TokenRefreshCoordinator(
      tokenStore: tokenStore,
      authSessionRefresher: refresher,
      now: { now }
    )

    let accessTokens = try await withThrowingTaskGroup(of: String.self, returning: [String].self) { group in
      for _ in 0 ..< 10 {
        group.addTask {
          try await coordinator.validAccessToken()
        }
      }

      var values: [String] = []
      for try await value in group {
        values.append(value)
      }
      return values
    }

    #expect(accessTokens == Array(repeating: "new-access-token", count: 10))
    #expect(await refresher.refreshCount == 1)
  }

  @Test("expired refresh token clears tokens")
  func expiredRefreshTokenClearsTokens() async {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    let tokenStore = MockCoordinatorTokenStore(tokens: .oldTokens(now: now, refreshTokenLifetime: -1))
    let refresher = MockCoordinatorSessionRefresher(result: .success(.newTokens(now: now)))
    let coordinator = TokenRefreshCoordinator(
      tokenStore: tokenStore,
      authSessionRefresher: refresher,
      now: { now }
    )

    do {
      _ = try await coordinator.validAccessToken()
      Issue.record("Expected expired refresh token error")
    } catch {
      #expect(error as? AuthSessionRefreshError == .expiredRefreshToken)
    }

    #expect(await tokenStore.storedTokens == nil)
    #expect(await refresher.refreshCount == 0)
  }

  @Test("failed refresh clears in-flight task for later retry")
  func failedRefreshCanRetryLater() async throws {
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    let tokenStore = MockCoordinatorTokenStore(tokens: .oldTokens(now: now, accessTokenLifetime: 10))
    let refresher = MockCoordinatorSessionRefresher(result: .failure(AuthSessionRefreshError.transport))
    let coordinator = TokenRefreshCoordinator(
      tokenStore: tokenStore,
      authSessionRefresher: refresher,
      now: { now }
    )

    do {
      _ = try await coordinator.validAccessToken()
      Issue.record("Expected refresh failure")
    } catch {
      #expect(error as? AuthSessionRefreshError == .transport)
    }

    await refresher.setResult(.success(.newTokens(now: now)))
    let accessToken = try await coordinator.validAccessToken()

    #expect(accessToken == "new-access-token")
    #expect(await refresher.refreshCount == 2)
  }
}

private actor MockCoordinatorTokenStore: AuthTokenStoring {
  private(set) var storedTokens: StoredAuthTokens?

  init(tokens: StoredAuthTokens?) {
    storedTokens = tokens
  }

  func save(_ tokens: StoredAuthTokens) async throws {
    storedTokens = tokens
  }

  func tokens() async throws -> StoredAuthTokens? {
    storedTokens
  }

  func delete() async throws {
    storedTokens = nil
  }
}

private actor MockCoordinatorSessionRefresher: AuthSessionRefreshing {
  private var result: Result<StoredAuthTokens, Error>
  private let delay: Duration?
  private(set) var refreshCount = 0

  init(
    result: Result<StoredAuthTokens, Error>,
    delay: Duration? = nil
  ) {
    self.result = result
    self.delay = delay
  }

  func setResult(_ result: Result<StoredAuthTokens, Error>) {
    self.result = result
  }

  func refreshSession() async throws -> StoredAuthTokens {
    refreshCount += 1
    if let delay {
      try await Task.sleep(for: delay)
    } else {
      await Task.yield()
    }
    return try result.get()
  }
}

private extension StoredAuthTokens {
  static func oldTokens(
    now: Date,
    accessTokenLifetime: TimeInterval = 10,
    refreshTokenLifetime: TimeInterval = 1_000
  ) -> StoredAuthTokens {
    StoredAuthTokens(
      accessToken: "old-access-token",
      refreshToken: "old-refresh-token",
      accessTokenExpiresAt: now.addingTimeInterval(accessTokenLifetime),
      refreshTokenExpiresAt: now.addingTimeInterval(refreshTokenLifetime)
    )
  }

  static func newTokens(now: Date) -> StoredAuthTokens {
    StoredAuthTokens(
      accessToken: "new-access-token",
      refreshToken: "new-refresh-token",
      accessTokenExpiresAt: now.addingTimeInterval(300),
      refreshTokenExpiresAt: now.addingTimeInterval(1_000)
    )
  }
}
