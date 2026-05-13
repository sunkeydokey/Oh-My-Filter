import Foundation
import SwiftData

@MainActor
final class SwiftDataPurchasedFilterStore: PurchasedFilterStoring {
  private let context: ModelContext

  init(context: ModelContext) {
    self.context = context
  }

  init(container: ModelContainer) {
    context = container.mainContext
  }

  func save(_ records: [PurchasedFilterRecord]) async throws {
    for record in records {
      let filterID = record.filterID
      let descriptor = FetchDescriptor<PurchasedFilterRecord>(
        predicate: #Predicate { $0.filterID == filterID }
      )
      if let existing = try? context.fetch(descriptor).first {
        existing.title = record.title
        existing.filterValuesData = record.filterValuesData
        existing.syncedAt = record.syncedAt
      } else {
        context.insert(record)
      }
    }
    do {
      try context.save()
    } catch {
      throw PurchasedFilterStoreError.saveFailed
    }
  }

  func loadAll() async throws -> [PurchasedFilterRecord] {
    let descriptor = FetchDescriptor<PurchasedFilterRecord>(
      sortBy: [SortDescriptor(\.syncedAt, order: .reverse)]
    )
    do {
      return try context.fetch(descriptor)
    } catch {
      throw PurchasedFilterStoreError.loadFailed
    }
  }

  func filterIDs() async throws -> Set<String> {
    let all = try await loadAll()
    return Set(all.map(\.filterID))
  }

  func deleteAll() async throws {
    try context.delete(model: PurchasedFilterRecord.self)
    try context.save()
  }
}
