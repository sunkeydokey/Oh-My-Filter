import CoreGraphics

nonisolated struct RenderedFilterImages: Equatable, Sendable {
  let original: CGImage
  let filtered: CGImage

  static func == (lhs: RenderedFilterImages, rhs: RenderedFilterImages) -> Bool {
    lhs.original === rhs.original && lhs.filtered === rhs.filtered
  }
}
