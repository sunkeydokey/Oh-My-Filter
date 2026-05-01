import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Oh_My_Filter

struct ImageCompressionUseCaseTests {
  @Test("small image compresses to jpeg within preset limit")
  func smallImageCompression() throws {
    let useCase = LiveImageCompressionUseCase()
    let data = try makeJPEGData(width: 24, height: 24, quality: 0.9)

    let compressed = try useCase.jpegData(from: data, preset: .profile)

    #expect(compressed.isEmpty == false)
    #expect(compressed.count <= ImageUploadPreset.profile.maxBytes)
  }

  @Test("large image is reduced under max bytes")
  func largeImageCompression() throws {
    let useCase = LiveImageCompressionUseCase()
    let data = try makeJPEGData(width: 2_000, height: 2_000, quality: 1.0)

    let compressed = try useCase.jpegData(from: data, preset: .chat)

    #expect(compressed.count <= ImageUploadPreset.chat.maxBytes)
  }

  @Test("invalid image data maps to compression error")
  func invalidImageData() {
    let useCase = LiveImageCompressionUseCase()

    #expect(throws: ImageCompressionError.invalidImageData) {
      _ = try useCase.jpegData(from: Data("not-image".utf8), preset: .chat)
    }
  }

  private func makeJPEGData(width: Int, height: Int, quality: Double) throws -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: width * 4,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      throw ImageCompressionError.compressionFailed
    }

    context.setFillColor(CGColor(red: 0.1, green: 0.7, blue: 0.65, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))

    guard let image = context.makeImage() else {
      throw ImageCompressionError.compressionFailed
    }

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
      data,
      UTType.jpeg.identifier as CFString,
      1,
      nil
    ) else {
      throw ImageCompressionError.compressionFailed
    }

    CGImageDestinationAddImage(
      destination,
      image,
      [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
    )

    guard CGImageDestinationFinalize(destination) else {
      throw ImageCompressionError.compressionFailed
    }

    return data as Data
  }
}
