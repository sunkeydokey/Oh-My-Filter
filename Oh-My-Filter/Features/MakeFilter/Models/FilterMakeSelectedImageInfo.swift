import CoreGraphics
import Foundation

nonisolated struct FilterMakeSelectedImageInfo: Equatable, Sendable {
  let imageData: Data?
  let previewImage: CGImage?
  let metadata: FilterDetailMetadata
  let filterParameterValues: [FilterEditParameter: Double]

  static func == (lhs: FilterMakeSelectedImageInfo, rhs: FilterMakeSelectedImageInfo) -> Bool {
    lhs.imageData == rhs.imageData
      && lhs.previewImage === rhs.previewImage
      && lhs.metadata == rhs.metadata
      && lhs.filterParameterValues == rhs.filterParameterValues
  }
}
