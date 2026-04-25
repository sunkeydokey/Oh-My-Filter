import Foundation

nonisolated struct LiveAuthSessionRefreshService: AuthSessionRefreshing {
  private let networkManager: any BaseNetworkManaging
  private let tokenStore: any AuthTokenStoring
  private let decoder: JSONDecoder
  private let now: @Sendable () -> Date

  init(
    networkManager: any BaseNetworkManaging = BaseNetworkManager(),
    tokenStore: any AuthTokenStoring,
    decoder: JSONDecoder = JSONDecoder(),
    now: @escaping @Sendable () -> Date = { .now }
  ) {
    self.networkManager = networkManager
    self.tokenStore = tokenStore
    self.decoder = decoder
    self.now = now
  }

  @MainActor
  init(
    networkManager: any BaseNetworkManaging = BaseNetworkManager(),
    decoder: JSONDecoder = JSONDecoder(),
    now: @escaping @Sendable () -> Date = { .now }
  ) {
    self.init(
      networkManager: networkManager,
      tokenStore: KeychainAuthTokenStore(),
      decoder: decoder,
      now: now
    )
  }

  func refreshSession() async throws -> StoredAuthTokens {
    guard let currentTokens = try await tokenStore.tokens() else {
      try await tokenStore.delete()
      throw AuthSessionRefreshError.missingRefreshToken
    }

    guard currentTokens.refreshTokenExpiresAt > now() else {
      try await tokenStore.delete()
      throw AuthSessionRefreshError.expiredRefreshToken
    }

    let response: NetworkResponse

    do {
      response = try await networkManager.request(
        AuthApiRouter.refresh,
        headers: [
          "RefreshToken": currentTokens.refreshToken,
          "Authorization": currentTokens.accessToken,
        ],
        parameters: .empty
      )
      print(response)
    } catch let error as NetworkError {
      throw mappedNetworkError(error)
    } catch {
      throw AuthSessionRefreshError.transport
    }

    switch response.statusCode {
    case 200 ..< 300:
      do {
        let decodedResponse = try decoder.decode(TokenRefreshResponseDTO.self, from: response.data)
        let refreshedTokens = decodedResponse.tokenPayload(now: now())
        print(refreshedTokens)
        try await tokenStore.save(refreshedTokens)
        return refreshedTokens
      } catch {
        throw AuthSessionRefreshError.invalidResponse
      }
    case 401:
      try await tokenStore.delete()
      throw AuthSessionRefreshError.unauthorizedRefreshToken
    case 418:
      try await tokenStore.delete()
      throw AuthSessionRefreshError.expiredRefreshToken
    default:
      throw AuthSessionRefreshError.serverError
    }
  }

  private func mappedNetworkError(_ error: NetworkError) -> AuthSessionRefreshError {
    switch error {
    case .invalidRequest:
      .invalidResponse
    case .invalidResponse:
      .invalidResponse
    case .transport:
      .transport
    }
  }
}
