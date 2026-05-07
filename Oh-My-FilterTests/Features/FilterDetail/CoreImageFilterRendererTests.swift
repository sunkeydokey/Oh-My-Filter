import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Oh_My_Filter

struct CoreImageFilterRendererTests {
  @Test("fixture image produces filtered output")
  func fixtureImageProducesFilteredOutput() async throws {
    let imageURL = try Self.writeTemporaryImageData(try Self.pngData(), fileName: "fixture.png")
    let renderer = CoreImageFilterRenderer()

    let images = try await renderer.render(
      originalImageURL: imageURL,
      filterValues: FilterValues(
        brightness: 0.1,
        contrast: 1.1,
        saturation: 1.2,
        exposure: 0,
        sharpen: 0.1,
        blur: 0,
        vignette: 0,
        noiseReduction: 0,
        highlights: 0,
        shadows: 0,
        temperature: 0,
        blackPoint: 0
      )
    )

    #expect(images.original.width == 2)
    #expect(images.filtered.height == 2)
  }

  @Test("invalid image data reports render failure")
  func invalidImageDataReportsFailure() async throws {
    let imageURL = try Self.writeTemporaryImageData(Data("not image".utf8), fileName: "invalid.txt")
    let renderer = CoreImageFilterRenderer()

    await #expect(throws: ImageFilterRenderingError.invalidImageData) {
      _ = try await renderer.render(
        originalImageURL: imageURL,
        filterValues: .neutral
      )
    }
  }

  @Test("neutral values preserve valid output image")
  func neutralValuesPreserveValidOutputImage() async throws {
    let imageURL = try Self.writeTemporaryImageData(try Self.pngData(), fileName: "neutral.png")
    let renderer = CoreImageFilterRenderer()

    let images = try await renderer.render(
      originalImageURL: imageURL,
      filterValues: .neutral
    )

    #expect(images.original.width == images.filtered.width)
    #expect(images.original.height == images.filtered.height)
  }

  @Test("EXIF orientation is applied before rendering")
  func exifOrientationIsAppliedBeforeRendering() async throws {
    let imageURL = try Self.writeTemporaryImageData(
      try Self.jpegData(width: 2, height: 3, orientation: 6),
      fileName: "oriented.jpeg"
    )
    let renderer = CoreImageFilterRenderer()

    let images = try await renderer.render(
      originalImageURL: imageURL,
      filterValues: .neutral
    )

    #expect(images.original.width == 3)
    #expect(images.original.height == 2)
    #expect(images.filtered.width == 3)
    #expect(images.filtered.height == 2)
  }

  @Test("preview render downsamples to requested maximum")
  func previewRenderDownsamplesToRequestedMaximum() async throws {
    let renderer = CoreImageFilterRenderer()
    let imageData = try Self.jpegData(width: 400, height: 200, orientation: 1)

    let image = try await renderer.renderPreview(
      originalImageData: imageData,
      maxPixelSize: 100,
      filterValues: .neutral
    )

    #expect(max(image.width, image.height) <= 100)
  }

  @Test("renderComparisonPreview downsamples to requested maximum pixel size")
  func renderComparisonPreviewDownsamples() async throws {
    let renderer = CoreImageFilterRenderer()
    let imageData = try Self.jpegData(width: 2000, height: 2000, orientation: 1)

    let images = try await renderer.renderComparisonPreview(
      originalImageData: imageData,
      maxPixelSize: 400,
      filterValues: .neutral
    )

    #expect(images.original.width <= 400)
    #expect(images.filtered.width <= 400)
  }

  @Test("renderComparisonPreview throws invalidImageData on bad input")
  func renderComparisonPreviewThrowsOnBadInput() async throws {
    let renderer = CoreImageFilterRenderer()

    await #expect(throws: ImageFilterRenderingError.invalidImageData) {
      _ = try await renderer.renderComparisonPreview(
        originalImageData: Data("not-image".utf8),
        maxPixelSize: 400,
        filterValues: .neutral
      )
    }
  }

  private static func pngData() throws -> Data {
    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(
      data,
      UTType.png.identifier as CFString,
      1,
      nil
    ))
    CGImageDestinationAddImage(destination, TestImageFactory.makeCGImage(), nil)
    #expect(CGImageDestinationFinalize(destination))
    return data as Data
  }

  private static func jpegData(width: Int, height: Int, orientation: Int) throws -> Data {
    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(
      data,
      UTType.jpeg.identifier as CFString,
      1,
      nil
    ))
    CGImageDestinationAddImage(
      destination,
      makeCGImage(width: width, height: height),
      [kCGImagePropertyOrientation: orientation] as CFDictionary
    )
    #expect(CGImageDestinationFinalize(destination))
    return data as Data
  }

  private static func makeCGImage(width: Int, height: Int) -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    context.setFillColor(CGColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    return context.makeImage()!
  }

  private static func writeTemporaryImageData(_ data: Data, fileName: String) throws -> URL {
    let directory = URL.temporaryDirectory.appending(path: "OhMyFilterRendererTests", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appending(path: "\(UUID().uuidString)-\(fileName)")
    try data.write(to: url)
    return url
  }
}
