import Foundation

struct SignupRequest: Codable, Equatable, Sendable {
  let email: String
  let password: String
  let nick: String
  let deviceToken: String?

  init(
    email: String,
    password: String,
    nick: String,
    deviceToken: String? = nil
  ) {
    self.email = email
    self.password = password
    self.nick = nick
    self.deviceToken = deviceToken
  }
}
