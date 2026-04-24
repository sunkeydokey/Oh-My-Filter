import Foundation

struct LoginRequest: Codable, Equatable, Sendable {
  let email: String
  let password: String
}
