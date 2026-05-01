import Foundation

nonisolated struct TokenRefreshResponseDTO: Codable, Sendable {
  let accessToken: String
  let refreshToken: String

  func tokenPayload(now: Date = .now) -> StoredAuthTokens {
    StoredAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: now.addingTimeInterval(5 * 60),
      refreshTokenExpiresAt: now.addingTimeInterval(1200 * 60)
    )
  }
}
