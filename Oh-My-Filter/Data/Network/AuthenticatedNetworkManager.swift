import Foundation

nonisolated struct AuthenticatedNetworkManager: AuthenticatedNetworkManaging {
  private let networkManager: any BaseNetworkManaging
  private let tokenStore: any AuthTokenStoring
  private let authSessionRefresher: any AuthSessionRefreshing

  init(
    networkManager: any BaseNetworkManaging = BaseNetworkManager(),
    tokenStore: any AuthTokenStoring = KeychainAuthTokenStore(),
    authSessionRefresher: (any AuthSessionRefreshing)? = nil
  ) {
    self.networkManager = networkManager
    self.tokenStore = tokenStore
    self.authSessionRefresher = authSessionRefresher ?? LiveAuthSessionRefreshService(
      networkManager: networkManager,
      tokenStore: tokenStore
    )
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try await performAuthenticatedRequest { accessToken in
      try await networkManager.request(
        router,
        headers: authorizationHeaders(accessToken: accessToken),
        parameters: parameters
      )
    }
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try await performAuthenticatedRequest { accessToken in
      try await networkManager.request(
        router,
        body: body,
        headers: authorizationHeaders(accessToken: accessToken),
        parameters: parameters
      )
    }
  }

  private func performAuthenticatedRequest(
    operation: (String) async throws -> NetworkResponse
  ) async throws -> NetworkResponse {
    let initialAccessToken = try await currentAccessToken()
    let initialResponse = try await operation(initialAccessToken)

    guard initialResponse.statusCode == 419 else {
      return initialResponse
    }

    let refreshedTokens: StoredAuthTokens

    do {
      refreshedTokens = try await authSessionRefresher.refreshSession()
    } catch {
      throw AuthenticatedNetworkError.refreshFailed
    }

    let retriedResponse = try await operation(refreshedTokens.accessToken)
    guard retriedResponse.statusCode != 419 else {
      throw AuthenticatedNetworkError.refreshFailed
    }

    return retriedResponse
  }

  private func currentAccessToken() async throws -> String {
    guard let accessToken = try await tokenStore.tokens()?.accessToken else {
      throw AuthenticatedNetworkError.missingAccessToken
    }

    return accessToken
  }

  private func authorizationHeaders(accessToken: String) -> [String: String] {
    ["Authorization": accessToken]
  }
}
