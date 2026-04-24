import Foundation

protocol AuthSessionRefreshing: Sendable {
  func refreshSession() async throws -> StoredAuthTokens
}

enum AuthSessionRefreshError: Error, Equatable, Sendable {
  case missingRefreshToken
  case expiredRefreshToken
  case unauthorizedRefreshToken
  case invalidResponse
  case transport
  case serverError
}
