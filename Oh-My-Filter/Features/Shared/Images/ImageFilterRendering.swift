import CoreGraphics
import Foundation

nonisolated protocol ImageFilterRendering: Sendable {
  func render(originalImageURL: URL, filterValues: FilterValues) async throws -> RenderedFilterImages
  func render(originalImageData: Data, filterValues: FilterValues) async throws -> RenderedFilterImages
  func renderPreview(
    originalImageData: Data,
    maxPixelSize: Int,
    filterValues: FilterValues
  ) async throws -> CGImage
}

nonisolated enum ImageFilterRenderingError: Error, Equatable, Sendable {
  case invalidImageData
  case renderFailed
}
