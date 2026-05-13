import Foundation

enum OfflineVideoStoreError: Error {
  case saveFailed
  case loadFailed
  case deleteFailed
}

protocol OfflineVideoStoring: Sendable {
  func save(_ record: OfflineVideoRecord) async throws
  func load(videoId: String) async throws -> OfflineVideoRecord?
  func delete(videoId: String) async throws
}
