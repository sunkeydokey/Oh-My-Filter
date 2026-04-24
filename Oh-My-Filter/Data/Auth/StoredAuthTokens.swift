import Foundation

nonisolated struct StoredAuthTokens: Codable, Equatable, Sendable {
  let accessToken: String
  let refreshToken: String
  let accessTokenExpiresAt: Date
  let refreshTokenExpiresAt: Date
}
