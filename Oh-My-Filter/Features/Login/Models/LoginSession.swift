import Foundation

struct LoginSession: Codable, Equatable, Sendable {
  let userID: String
  let email: String
  let nick: String
  let profileImage: String?
  let accessToken: String
  let refreshToken: String
}
