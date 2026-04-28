import Foundation

struct AppleLoginRequest: Codable, Equatable, Sendable {
  let idToken: String
  let deviceToken: String?

  init(
    idToken: String,
    deviceToken: String? = nil
  ) {
    self.idToken = idToken
    self.deviceToken = deviceToken
  }
}
