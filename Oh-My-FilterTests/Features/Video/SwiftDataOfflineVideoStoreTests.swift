import Foundation
import SwiftData
import Testing
@testable import Oh_My_Filter

@MainActor
@Suite(.serialized)
struct SwiftDataOfflineVideoStoreTests {
  func makeStore() throws -> SwiftDataOfflineVideoStore {
    let container = try ModelContainer(
      for: OfflineVideoRecord.self,
      configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return SwiftDataOfflineVideoStore(container: container)
  }

  @Test("save inserts a new record")
  func saveInsertsRecord() async throws {
    let store = try makeStore()
    let record = OfflineVideoRecord(videoId: "v1", localPath: "videos/v1.movpkg", title: "영상 1")

    try await store.save(record)

    let loaded = try await store.load(videoId: "v1")
    #expect(loaded?.videoId == "v1")
    #expect(loaded?.localPath == "videos/v1.movpkg")
    #expect(loaded?.title == "영상 1")
  }

  @Test("save updates existing record with same videoId")
  func saveUpdatesExistingRecord() async throws {
    let store = try makeStore()
    let record = OfflineVideoRecord(videoId: "v1", localPath: "videos/v1.movpkg", title: "영상 1")
    try await store.save(record)

    let updated = OfflineVideoRecord(videoId: "v1", localPath: "videos/v1-new.movpkg", title: "영상 1 업데이트")
    try await store.save(updated)

    let loaded = try await store.load(videoId: "v1")
    #expect(loaded?.localPath == "videos/v1-new.movpkg")
    #expect(loaded?.title == "영상 1 업데이트")
  }

  @Test("load returns nil for unknown videoId")
  func loadReturnsNilForUnknown() async throws {
    let store = try makeStore()

    let result = try await store.load(videoId: "unknown")

    #expect(result == nil)
  }

  @Test("delete removes the record")
  func deleteRemovesRecord() async throws {
    let store = try makeStore()
    let record = OfflineVideoRecord(videoId: "v1", localPath: "videos/v1.movpkg", title: "영상 1")
    try await store.save(record)

    try await store.delete(videoId: "v1")

    let loaded = try await store.load(videoId: "v1")
    #expect(loaded == nil)
  }

  @Test("delete on non-existent videoId is a no-op")
  func deleteNonExistentIsNoOp() async throws {
    let store = try makeStore()

    try await store.delete(videoId: "does-not-exist")
  }
}
