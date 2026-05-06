import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Oh_My_Filter

struct LiveFilterMakeImageInfoReaderTests {
  @Test("reader extracts exif metadata and embedded filter values")
  func readerExtractsImageInfo() async throws {
    let reader = LiveFilterMakeImageInfoReader()
    let data = try makeJPEGData()

    let info = await reader.selectedImageInfo(from: data)

    #expect(info.metadata.camera == "Apple iPhone 16 Pro")
    #expect(info.previewImage?.width == 24)
    #expect(info.previewImage?.height == 24)
    #expect(info.metadata.lens == "Wide 26 mm")
    #expect(info.metadata.focalLength == "26 mm")
    #expect(info.metadata.aperture == "f 1.8")
    #expect(info.metadata.iso == "400")
    #expect(info.filterParameterValues[.brightness] == 0.44)
    #expect(info.filterParameterValues[.noiseReduction] == 0.7)
    #expect(info.filterParameterValues[.temperature] == 7_200)
    #expect(info.filterParameterValues[.contrast] == FilterEditParameter.contrast.defaultValue)
  }

  private func makeJPEGData() throws -> Data {
    let width = 24
    let height = 24
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

    let properties: [CFString: Any] = [
      kCGImagePropertyTIFFDictionary: [
        kCGImagePropertyTIFFMake: "Apple",
        kCGImagePropertyTIFFModel: "iPhone 16 Pro",
      ],
      kCGImagePropertyExifDictionary: [
        kCGImagePropertyExifLensModel: "Wide 26 mm",
        kCGImagePropertyExifFocalLength: 26,
        kCGImagePropertyExifFNumber: 1.8,
        kCGImagePropertyExifExposureTime: 0.008333,
        kCGImagePropertyExifISOSpeedRatings: [400],
        kCGImagePropertyExifUserComment: """
        {"filter_values":{"brightness":0.44,"noise_reduction":0.7,"temperature":7200}}
        """,
      ],
    ]

    CGImageDestinationAddImage(destination, image, properties as CFDictionary)

    guard CGImageDestinationFinalize(destination) else {
      throw ImageCompressionError.compressionFailed
    }

    return data as Data
  }
}
