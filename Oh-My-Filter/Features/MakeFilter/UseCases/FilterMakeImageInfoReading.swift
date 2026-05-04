import Foundation

protocol FilterMakeImageInfoReading: Sendable {
  func selectedImageInfo(from imageData: Data?) -> FilterMakeSelectedImageInfo
}
