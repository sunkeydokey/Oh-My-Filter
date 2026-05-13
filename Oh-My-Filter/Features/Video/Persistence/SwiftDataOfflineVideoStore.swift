import Foundation
import SwiftData

@MainActor
final class SwiftDataOfflineVideoStore: OfflineVideoStoring {
  private let context: ModelContext

  init(context: ModelContext) {
    self.context = context
  }

  init(container: ModelContainer) {
    context = container.mainContext
  }

  func save(_ record: OfflineVideoRecord) async throws {
    let videoId = record.videoId
    let descriptor = FetchDescriptor<OfflineVideoRecord>(
      predicate: #Predicate { $0.videoId == videoId }
    )
    if let existing = try? context.fetch(descriptor).first {
      existing.localPath = record.localPath
      existing.title = record.title
      existing.savedAt = record.savedAt
    } else {
      context.insert(record)
    }
    do {
      try context.save()
    } catch {
      throw OfflineVideoStoreError.saveFailed
    }
  }

  func load(videoId: String) async throws -> OfflineVideoRecord? {
    let descriptor = FetchDescriptor<OfflineVideoRecord>(
      predicate: #Predicate { $0.videoId == videoId }
    )
    do {
      return try context.fetch(descriptor).first
    } catch {
      throw OfflineVideoStoreError.loadFailed
    }
  }

  func delete(videoId: String) async throws {
    let descriptor = FetchDescriptor<OfflineVideoRecord>(
      predicate: #Predicate { $0.videoId == videoId }
    )
    guard let record = try? context.fetch(descriptor).first else { return }
    try? FileManager.default.removeItem(at: record.localURL)
    context.delete(record)
    do {
      try context.save()
    } catch {
      throw OfflineVideoStoreError.deleteFailed
    }
  }
}
