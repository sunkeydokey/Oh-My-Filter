import Foundation

struct LoginRequest: Codable, Equatable, Sendable {
  let email: String
  let password: String
  let deviceToken: String?

  init(
    email: String,
    password: String,
    deviceToken: String? = nil
  ) {
    self.email = email
    self.password = password
    self.deviceToken = deviceToken
  }
}
