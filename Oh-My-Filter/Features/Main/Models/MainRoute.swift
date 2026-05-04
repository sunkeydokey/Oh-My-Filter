import Foundation

nonisolated enum MainRoute: Hashable, Sendable {
  case filterDetail(filterID: String)
  case filterMake
  case filterEdit(FilterMakeDraft)
}
