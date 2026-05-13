import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

nonisolated protocol ImageCompressionUseCase: Sendable {
  func jpegData(from imageData: Data, preset: ImageUploadPreset) throws -> Data
}

nonisolated enum ImageCompressionError: Error, Equatable, Sendable {
  case invalidImageData
  case compressionFailed
  case exceedsMaximumBytes
  case unsupportedFileExtension
}

nonisolated struct LiveImageCompressionUseCase: ImageCompressionUseCase {
  func jpegData(from imageData: Data, preset: ImageUploadPreset) throws -> Data {
    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
      throw ImageCompressionError.invalidImageData
    }

    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
      throw ImageCompressionError.invalidImageData
    }

    let width = properties[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
    let height = properties[kCGImagePropertyPixelHeight] as? CGFloat ?? 0
    guard width > 0, height > 0 else {
      throw ImageCompressionError.invalidImageData
    }

    let originalMaxDimension = max(width, height)
    var maxPixelSize = Int(originalMaxDimension)

    while true {
      let image = try thumbnail(from: source, maxPixelSize: maxPixelSize)
      if let compressed = try compressedData(for: image, preset: preset) {
        return compressed
      }
      guard maxPixelSize > 320 else { break }
      maxPixelSize = Int(Double(maxPixelSize) * 0.8)
    }

    throw ImageCompressionError.exceedsMaximumBytes
  }

  private func thumbnail(from source: CGImageSource, maxPixelSize: Int) throws -> CGImage {
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ]

    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
      throw ImageCompressionError.invalidImageData
    }

    return image
  }

  private func compressedData(
    for image: CGImage,
    preset: ImageUploadPreset
  ) throws -> Data? {
    var quality = preset.jpegQualityRange.upperBound
    let lowerBound = preset.jpegQualityRange.lowerBound

    while quality >= lowerBound {
      let data = try encode(image: image, quality: quality)
      if data.count <= preset.maxBytes {
        return data
      }
      quality -= 0.1
    }

    return nil
  }

  private func encode(image: CGImage, quality: Double) throws -> Data {
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
      data,
      UTType.jpeg.identifier as CFString,
      1,
      nil
    ) else {
      throw ImageCompressionError.compressionFailed
    }

    let options: [CFString: Any] = [
      kCGImageDestinationLossyCompressionQuality: quality,
    ]
    CGImageDestinationAddImage(destination, image, options as CFDictionary)

    guard CGImageDestinationFinalize(destination) else {
      throw ImageCompressionError.compressionFailed
    }

    return data as Data
  }
}
