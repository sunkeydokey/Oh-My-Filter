import Foundation

nonisolated enum AppTokenRefreshCoordinator {
  static let shared: any TokenRefreshCoordinating = {
    let tokenStore = KeychainAuthTokenStore()
    let networkManager = BaseNetworkManager(tokenStore: tokenStore)
    let authSessionRefresher = LiveAuthSessionRefreshService(
      networkManager: networkManager,
      tokenStore: tokenStore
    )

    return TokenRefreshCoordinator(
      tokenStore: tokenStore,
      authSessionRefresher: authSessionRefresher
    )
  }()
}
