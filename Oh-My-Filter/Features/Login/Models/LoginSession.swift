import Foundation

nonisolated struct LoginSession: Codable, Equatable, Sendable {
  let userID: String
  let email: String
  let nick: String
  let profileImage: String?
}
