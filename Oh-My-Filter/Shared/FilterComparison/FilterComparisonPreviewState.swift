import Foundation

nonisolated enum FilterComparisonPreviewState: Equatable, Sendable {
  case rendering
  case rendered(RenderedFilterImages)
  case fallback(originalImageURL: URL?, filteredImageURL: URL?)
}
