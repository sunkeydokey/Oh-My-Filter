import Foundation

nonisolated struct FilterMakeSelectedImageInfo: Equatable, Sendable {
  let imageData: Data?
  let metadata: FilterDetailMetadata
  let filterParameterValues: [FilterEditParameter: Double]
}
