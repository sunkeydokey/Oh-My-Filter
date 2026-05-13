import Foundation
import OSLog

final class LivePurchasedFilterSyncUseCase: PurchasedFilterSyncing {
  private let orderService: any OrderHistoryServicing
  private let filterDetailService: any FilterDetailServicing
  private let store: any PurchasedFilterStoring
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "PurchasedFilterSync"
  )

  init(
    orderService: any OrderHistoryServicing,
    filterDetailService: any FilterDetailServicing,
    store: any PurchasedFilterStoring
  ) {
    self.orderService = orderService
    self.filterDetailService = filterDetailService
    self.store = store
  }

  func sync() async {
    do {
      let orders = try await orderService.loadOrders()
      let localIDs = try await store.filterIDs()

      let missingFilterIDs = orders
        .map(\.filter.id)
        .filter { !localIDs.contains($0) }

      guard !missingFilterIDs.isEmpty else { return }

      let fetchedDetails = await withTaskGroup(
        of: FilterDetail?.self,
        returning: [FilterDetail].self
      ) { group in
        for filterID in missingFilterIDs {
          group.addTask { [filterDetailService] in
            try? await filterDetailService.loadFilterDetail(filterID: filterID)
          }
        }
        var results: [FilterDetail] = []
        for await detail in group {
          if let detail { results.append(detail) }
        }
        return results
      }

      let records = fetchedDetails.map { detail in
        PurchasedFilterRecord(
          filterID: detail.id,
          title: detail.title,
          filterValues: detail.filterValues
        )
      }

      try await store.save(records)
      Self.logger.info("ℹ️ [PurchasedFilterSync] synced \(records.count) new filters")
    } catch {
      Self.logger.error("❌ [PurchasedFilterSync] sync failed: \(String(describing: error), privacy: .public)")
    }
  }
}
