import Foundation

protocol FilterMakeImageInfoReading: Sendable {
  func selectedImageInfo(from imageData: Data?) async -> FilterMakeSelectedImageInfo
}
