import CoreGraphics
import Foundation

nonisolated protocol ImageFilterRendering: Sendable {
  func render(originalImageURL: URL, filterValues: FilterValues) async throws -> RenderedFilterImages
}

nonisolated enum ImageFilterRenderingError: Error, Equatable, Sendable {
  case invalidImageData
  case renderFailed
}
