import Foundation

nonisolated protocol TokenRefreshCoordinating: Sendable {
  func prepareValidTokenIfNeeded() async throws
  func validAccessToken() async throws -> String
  func authorizationHeaderValue() async throws -> String
  func forceRefresh() async throws -> StoredAuthTokens
  func clearTokens() async throws
}

actor TokenRefreshCoordinator: TokenRefreshCoordinating {
  private let tokenStore: any AuthTokenStoring
  private let authSessionRefresher: any AuthSessionRefreshing
  private let refreshLeeway: TimeInterval
  private let now: @Sendable () -> Date
  private var refreshTask: Task<StoredAuthTokens, Error>?

  init(
    tokenStore: any AuthTokenStoring,
    authSessionRefresher: any AuthSessionRefreshing,
    refreshLeeway: TimeInterval = 90,
    now: @escaping @Sendable () -> Date = { .now }
  ) {
    self.tokenStore = tokenStore
    self.authSessionRefresher = authSessionRefresher
    self.refreshLeeway = refreshLeeway
    self.now = now
  }

  func prepareValidTokenIfNeeded() async throws {
    _ = try await validAccessToken()
  }

  func validAccessToken() async throws -> String {
    let tokens = try await currentTokens()
    guard tokens.refreshTokenExpiresAt > now() else {
      try await clearTokens()
      throw AuthSessionRefreshError.expiredRefreshToken
    }

    guard shouldRefresh(accessTokenExpiresAt: tokens.accessTokenExpiresAt) else {
      return tokens.accessToken
    }

    return try await refresh().accessToken
  }

  func authorizationHeaderValue() async throws -> String {
    try await validAccessToken()
  }

  func forceRefresh() async throws -> StoredAuthTokens {
    let tokens = try await currentTokens()
    guard tokens.refreshTokenExpiresAt > now() else {
      try await clearTokens()
      throw AuthSessionRefreshError.expiredRefreshToken
    }

    return try await refresh()
  }

  func clearTokens() async throws {
    refreshTask?.cancel()
    refreshTask = nil
    try await tokenStore.delete()
  }

  private func currentTokens() async throws -> StoredAuthTokens {
    guard let tokens = try await tokenStore.tokens() else {
      throw AuthSessionRefreshError.missingRefreshToken
    }

    return tokens
  }

  private func shouldRefresh(accessTokenExpiresAt: Date) -> Bool {
    accessTokenExpiresAt.timeIntervalSince(now()) < refreshLeeway
  }

  private func refresh() async throws -> StoredAuthTokens {
    if let refreshTask {
      return try await refreshTask.value
    }

    let authSessionRefresher = authSessionRefresher
    let task = Task {
      try await authSessionRefresher.refreshSession()
    }
    refreshTask = task

    do {
      let tokens = try await task.value
      refreshTask = nil
      return tokens
    } catch {
      refreshTask = nil
      throw error
    }
  }
}
