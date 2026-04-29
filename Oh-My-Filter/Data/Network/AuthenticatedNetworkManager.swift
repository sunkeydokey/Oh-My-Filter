import Foundation

nonisolated struct AuthenticatedNetworkManager: AuthenticatedNetworkManaging {
  private let networkManager: any BaseNetworkManaging
  private let tokenRefreshCoordinator: any TokenRefreshCoordinating

  init(
    networkManager: any BaseNetworkManaging,
    tokenStore: any AuthTokenStoring,
    authSessionRefresher: (any AuthSessionRefreshing)? = nil
  ) {
    self.networkManager = networkManager
    let resolvedRefresher = authSessionRefresher ?? LiveAuthSessionRefreshService(
      networkManager: networkManager,
      tokenStore: tokenStore
    )
    self.tokenRefreshCoordinator = TokenRefreshCoordinator(
      tokenStore: tokenStore,
      authSessionRefresher: resolvedRefresher
    )
  }

  init(
    networkManager: any BaseNetworkManaging,
    tokenRefreshCoordinator: any TokenRefreshCoordinating
  ) {
    self.networkManager = networkManager
    self.tokenRefreshCoordinator = tokenRefreshCoordinator
  }

  init(networkManager: any BaseNetworkManaging) {
    self.init(
      networkManager: networkManager,
      tokenRefreshCoordinator: AppTokenRefreshCoordinator.shared
    )
  }

  @MainActor
  init() {
    self.init(networkManager: BaseNetworkManager())
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
    let accessToken = try await tokenRefreshCoordinator.authorizationHeaderValue()
    let response = try await operation(accessToken)

    if response.statusCode == 401 || response.statusCode == 419 {
      try await tokenRefreshCoordinator.clearTokens()
      throw AuthenticatedNetworkError.sessionExpired
    }

    return response
  }

  private func authorizationHeaders(accessToken: String) -> [String: String] {
    ["Authorization": accessToken]
  }
}
