import Foundation

struct KakaoLoginRequest: Codable, Equatable, Sendable {
  let oauthToken: String
  let deviceToken: String?

  init(
    oauthToken: String,
    deviceToken: String? = nil
  ) {
    self.oauthToken = oauthToken
    self.deviceToken = deviceToken
  }
}
