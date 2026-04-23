import Foundation

struct SignupRequest: Codable, Equatable, Sendable {
  let email: String
  let password: String
  let nick: String
}
