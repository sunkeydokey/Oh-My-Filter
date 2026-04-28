import Foundation

protocol KakaoOAuthProviding: Sendable {
  func accessToken() async throws -> String
}
