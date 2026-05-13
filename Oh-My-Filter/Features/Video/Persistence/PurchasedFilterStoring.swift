import Foundation

protocol PurchasedFilterStoring: Sendable {
  func save(_ records: [PurchasedFilterRecord]) async throws
  func loadAll() async throws -> [PurchasedFilterRecord]
  func filterIDs() async throws -> Set<String>
  func deleteAll() async throws
}

enum PurchasedFilterStoreError: Error, Equatable, Sendable {
  case saveFailed
  case loadFailed
}
