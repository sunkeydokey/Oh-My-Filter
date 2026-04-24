import Foundation

nonisolated struct LoginResponseDTO: Codable, Sendable {
  let userID: String
  let email: String
  let nick: String
  let profileImage: String?
  let accessToken: String
  let refreshToken: String

  enum CodingKeys: String, CodingKey {
    case userID = "user_id"
    case email
    case nick
    case profileImage
    case accessToken
    case refreshToken
  }

  var session: LoginSession {
    LoginSession(
      userID: userID,
      email: email,
      nick: nick,
      profileImage: profileImage
    )
  }

  func tokenPayload(now: Date = .now) -> StoredAuthTokens {
    StoredAuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: now.addingTimeInterval(120 * 60),
      refreshTokenExpiresAt: now.addingTimeInterval(12_000 * 60)
    )
  }
}
