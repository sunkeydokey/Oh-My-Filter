import Foundation

nonisolated protocol AuthenticatedImageDataLoading: Sendable {
  func loadImageData(from url: URL) async throws -> Data
}

nonisolated struct LiveAuthenticatedImageDataLoader: AuthenticatedImageDataLoading {
  private let session: URLSession
  private let tokenRefreshCoordinator: any TokenRefreshCoordinating

  init(
    session: URLSession = .shared,
    tokenRefreshCoordinator: any TokenRefreshCoordinating = AppTokenRefreshCoordinator.shared
  ) {
    self.session = session
    self.tokenRefreshCoordinator = tokenRefreshCoordinator
  }

  func loadImageData(from url: URL) async throws -> Data {
    var request = URLRequest(url: url)
    request.setValue(Server.apiKey(), forHTTPHeaderField: "SeSACKey")
    if let accessToken = try? await tokenRefreshCoordinator.authorizationHeaderValue() {
      request.setValue(accessToken, forHTTPHeaderField: "Authorization")
    }

    let (data, _) = try await session.data(for: request)
    return data
  }
}
