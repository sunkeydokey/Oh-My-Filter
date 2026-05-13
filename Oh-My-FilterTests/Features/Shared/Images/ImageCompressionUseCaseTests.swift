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

  @Test("community post video uses upload byte limit")
  func communityPostVideoUsesUploadByteLimit() async throws {
    let useCase = LiveImageUploadUseCase(movConversionUseCase: StubMOVToMP4ConversionUseCase())
    let underLimit = Data(repeating: 0, count: ImageUploadPreset.communityPost.maxBytes)

    let parts = try await useCase.multipartFiles(
      from: [
        PhotoPickerUploadSelection(
          data: underLimit,
          fileName: "clip.mp4",
          mediaKind: .video,
          mimeType: "video/mp4"
        ),
      ],
      preset: .communityPost
    )

    #expect(parts.first?.data.count == underLimit.count)

    await #expect(throws: ImageCompressionError.exceedsMaximumBytes) {
      _ = try await useCase.multipartFiles(
        from: [
          PhotoPickerUploadSelection(
            data: Data(repeating: 0, count: ImageUploadPreset.communityPost.maxBytes + 1),
            fileName: "clip.mp4",
            mediaKind: .video,
            mimeType: "video/mp4"
          ),
        ],
        preset: .communityPost
      )
    }
  }

  @Test("MOV video is converted to MP4 data and filename")
  func movVideoIsConvertedToMP4() async throws {
    let convertedData = Data("converted-mp4".utf8)
    let useCase = LiveImageUploadUseCase(
      movConversionUseCase: StubMOVToMP4ConversionUseCase(output: convertedData)
    )
    let selection = PhotoPickerUploadSelection(
      data: Data("mov-raw".utf8),
      fileName: "clip.mov",
      mediaKind: .video,
      mimeType: "video/quicktime"
    )

    let parts = try await useCase.multipartFiles(from: [selection], preset: .communityPost)

    #expect(parts.first?.fileName == "clip.mp4")
    #expect(parts.first?.mimeType == "video/mp4")
    #expect(parts.first?.data == convertedData)
  }

  @Test("community post video upload normalizes extensions to mp4")
  func communityPostVideoUploadNormalizesExtensions() async throws {
    let useCase = LiveImageUploadUseCase(movConversionUseCase: StubMOVToMP4ConversionUseCase())

    for fileExtension in ["mp4", "avi", "mkv", "wmv"] {
      let parts = try await useCase.multipartFiles(
        from: [
          PhotoPickerUploadSelection(
            data: Data("video".utf8),
            fileName: "clip.\(fileExtension)",
            mediaKind: .video,
            mimeType: "video/mp4"
          ),
        ],
        preset: .communityPost
      )

      #expect(parts.first?.fileName == "clip.mp4")
      #expect(parts.first?.mimeType == "video/mp4")
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

private struct StubMOVToMP4ConversionUseCase: MOVToMP4ConversionUseCase {
  let output: Data

  init(output: Data = Data("converted".utf8)) {
    self.output = output
  }

  func mp4Data(from movData: Data) async throws -> Data {
    output
  }
}
