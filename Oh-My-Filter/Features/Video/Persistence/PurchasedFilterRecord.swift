import Foundation
import SwiftData

@Model
final class PurchasedFilterRecord {
  @Attribute(.unique) var filterID: String
  var title: String
  var filterValuesData: Data
  var syncedAt: Date

  init(filterID: String, title: String, filterValues: FilterValues, syncedAt: Date = Date()) {
    self.filterID = filterID
    self.title = title
    self.filterValuesData = (try? JSONEncoder().encode(filterValues)) ?? Data()
    self.syncedAt = syncedAt
  }

  var filterValues: FilterValues? {
    try? JSONDecoder().decode(FilterValues.self, from: filterValuesData)
  }
}
