import Foundation

protocol AuthTokenStoring: Sendable {
  func save(_ tokens: StoredAuthTokens) async throws
  func tokens() async throws -> StoredAuthTokens?
  func delete() async throws
}
