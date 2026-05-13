import Foundation
import Observation
import OSLog
import SwiftData

@MainActor
@Observable
final class PurchasedFilterStore {
  var purchasedFilters: [PurchasedFilterRecord] = []

  private let localStore: any PurchasedFilterStoring
  private let syncUseCase: any PurchasedFilterSyncing
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "PurchasedFilterStore"
  )

  init(localStore: any PurchasedFilterStoring, syncUseCase: any PurchasedFilterSyncing) {
    self.localStore = localStore
    self.syncUseCase = syncUseCase
  }

  @MainActor
  convenience init(container: ModelContainer) {
    let swiftDataStore = SwiftDataPurchasedFilterStore(container: container)
    let syncUseCase = LivePurchasedFilterSyncUseCase(
      orderService: LiveOrderHistoryService(),
      filterDetailService: LiveFilterDetailService(),
      store: swiftDataStore
    )
    self.init(localStore: swiftDataStore, syncUseCase: syncUseCase)
  }

  func load() async {
    do {
      purchasedFilters = try await localStore.loadAll()
    } catch {
      Self.logger.error("❌ [PurchasedFilterStore] load failed: \(String(describing: error), privacy: .public)")
    }
  }

  func sync() async {
    await syncUseCase.sync()
    await load()
  }
}
