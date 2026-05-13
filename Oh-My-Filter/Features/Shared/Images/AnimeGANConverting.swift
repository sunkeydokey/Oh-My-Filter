import CoreGraphics
import CoreImage
import CoreML
import Foundation
import ImageIO

nonisolated struct AnimeConversionResult: Sendable {
  let originalPreview: CGImage
  let convertedPreview: CGImage
  let convertedData: Data
}

extension AnimeConversionResult: Equatable {
  static func == (lhs: AnimeConversionResult, rhs: AnimeConversionResult) -> Bool {
    lhs.originalPreview === rhs.originalPreview
      && lhs.convertedPreview === rhs.convertedPreview
      && lhs.convertedData == rhs.convertedData
  }
}

nonisolated enum AnimeGANConversionError: Error, Equatable, Sendable {
  case invalidImageData
  case modelLoadFailed
  case predictionFailed
  case outputDecodingFailed
}

nonisolated protocol AnimeGANConverting: Sendable {
  func convert(imageData: Data, maxPixelSize: Int) async throws -> AnimeConversionResult
}

nonisolated struct LiveAnimeGANConverter: AnimeGANConverting {
  func convert(imageData: Data, maxPixelSize: Int) async throws -> AnimeConversionResult {
    try await Task.detached(priority: .userInitiated) {
      try Self.convertSync(imageData: imageData, maxPixelSize: maxPixelSize)
    }.value
  }

  private static func convertSync(imageData: Data, maxPixelSize: Int) throws -> AnimeConversionResult {
    // 1. Decode source to thumbnail at maxPixelSize
    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
      throw AnimeGANConversionError.invalidImageData
    }

    let thumbOptions: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: max(maxPixelSize, 1),
    ]
    guard let originalThumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary) else {
      throw AnimeGANConversionError.invalidImageData
    }

    // 2. Load model and run prediction using generated input convenience init
    let model: animeganHayao
    do {
      model = try animeganHayao()
    } catch {
      throw AnimeGANConversionError.modelLoadFailed
    }

    let input: animeganHayaoInput
    do {
      // Squash-resize to 256×256 via MLFeatureValue (ARGB pixel buffer)
      input = try animeganHayaoInput(test__0With: originalThumbnail)
    } catch {
      throw AnimeGANConversionError.invalidImageData
    }

    let output: animeganHayaoOutput
    do {
      output = try model.prediction(input: input)
    } catch {
      throw AnimeGANConversionError.predictionFailed
    }

    // 3. Convert output pixel buffer to CGImage
    let context = CIContext(options: [.cacheIntermediates: false])
    let ciConverted = CIImage(cvPixelBuffer: output.image)
    guard let converted256 = context.createCGImage(ciConverted, from: ciConverted.extent) else {
      throw AnimeGANConversionError.outputDecodingFailed
    }

    // 4. Upscale back to original thumbnail dimensions via Lanczos
    let targetWidth = CGFloat(originalThumbnail.width)
    let targetHeight = CGFloat(originalThumbnail.height)
    let upScaleX = targetWidth / CGFloat(converted256.width)
    let upScaleY = targetHeight / CGFloat(converted256.height)

    let upScaled = CIImage(cgImage: converted256)
      .applyingFilter("CILanczosScaleTransform", parameters: [
        kCIInputScaleKey: max(upScaleX, upScaleY),
        kCIInputAspectRatioKey: upScaleX / upScaleY,
      ])

    let outputExtent = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
    guard let convertedPreview = context.createCGImage(upScaled, from: outputExtent) else {
      throw AnimeGANConversionError.outputDecodingFailed
    }

    // 5. JPEG encode converted image
    let jpegData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(jpegData, "public.jpeg" as CFString, 1, nil) else {
      throw AnimeGANConversionError.outputDecodingFailed
    }
    CGImageDestinationAddImage(
      destination,
      convertedPreview,
      [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary
    )
    guard CGImageDestinationFinalize(destination) else {
      throw AnimeGANConversionError.outputDecodingFailed
    }

    return AnimeConversionResult(
      originalPreview: originalThumbnail,
      convertedPreview: convertedPreview,
      convertedData: jpegData as Data
    )
  }
}
