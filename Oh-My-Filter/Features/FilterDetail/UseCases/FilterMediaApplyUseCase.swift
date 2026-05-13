import AVFoundation
import CoreGraphics
import Foundation
import UIKit
import UniformTypeIdentifiers

nonisolated enum FilterMediaKind: Equatable, Sendable {
  case image
  case video
}

nonisolated struct FilterMediaInput: Equatable, Sendable {
  let data: Data
  let fileName: String
  let kind: FilterMediaKind
  let mimeType: String
}

nonisolated enum FilterMediaOutput: Identifiable, Sendable {
  case image(id: UUID, cgImage: CGImage, uploadSelection: PhotoPickerUploadSelection)
  case video(id: UUID, fileURL: URL, uploadSelection: PhotoPickerUploadSelection)

  var id: UUID {
    switch self {
    case let .image(id, _, _), let .video(id, _, _):
      id
    }
  }

  var uploadSelection: PhotoPickerUploadSelection {
    switch self {
    case let .image(_, _, selection), let .video(_, _, selection):
      selection
    }
  }

  var isImage: Bool {
    if case .image = self { return true }
    return false
  }
}

nonisolated extension FilterMediaOutput: Equatable {
  nonisolated static func == (lhs: FilterMediaOutput, rhs: FilterMediaOutput) -> Bool {
    switch (lhs, rhs) {
    case let (.image(lID, lImage, lSelection), .image(rID, rImage, rSelection)):
      lID == rID && lImage === rImage && lSelection == rSelection
    case let (.video(lID, lURL, lSelection), .video(rID, rURL, rSelection)):
      lID == rID && lURL == rURL && lSelection == rSelection
    default:
      false
    }
  }
}

nonisolated protocol FilterMediaApplying: Sendable {
  func apply(input: FilterMediaInput, filterValues: FilterValues) async throws -> FilterMediaOutput
}

nonisolated enum FilterMediaApplyError: Error, Equatable, Sendable {
  case invalidVideo
  case exportUnavailable
  case exportFailed
}

nonisolated struct LiveFilterMediaApplyUseCase: FilterMediaApplying {
  private let renderer: any ImageFilterRendering

  init(renderer: any ImageFilterRendering = CoreImageFilterRenderer()) {
    self.renderer = renderer
  }

  func apply(input: FilterMediaInput, filterValues: FilterValues) async throws -> FilterMediaOutput {
    switch input.kind {
    case .image:
      let rendered = try await renderer.render(originalImageData: input.data, filterValues: filterValues)
      guard let data = UIImage(cgImage: rendered.filtered).jpegData(compressionQuality: 0.9) else {
        throw ImageFilterRenderingError.renderFailed
      }
      let selection = PhotoPickerUploadSelection(
        data: data,
        fileName: fileName(from: input.fileName, fileExtension: "jpg"),
        mediaKind: .image,
        mimeType: "image/jpeg"
      )
      return .image(id: selection.id, cgImage: rendered.filtered, uploadSelection: selection)

    case .video:
      let sourceURL = try writeTemporaryFile(data: input.data, fileName: input.fileName)
      let outputURL = temporaryOutputURL(fileExtension: "mov")
      let asset = AVURLAsset(url: sourceURL)
      guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
        throw FilterMediaApplyError.exportUnavailable
      }

      exportSession.videoComposition = try await VideoFilterComposition.make(for: asset, filterValues: filterValues)
      exportSession.shouldOptimizeForNetworkUse = true
      try await exportSession.export(to: outputURL, as: .mov)

      let data = try Data(contentsOf: outputURL)
      let selection = PhotoPickerUploadSelection(
        data: data,
        fileName: fileName(from: input.fileName, fileExtension: "mov"),
        mediaKind: .video,
        mimeType: "video/quicktime"
      )
      return .video(id: selection.id, fileURL: outputURL, uploadSelection: selection)
    }
  }

  private func writeTemporaryFile(data: Data, fileName: String) throws -> URL {
    let url = FileManager.default.temporaryDirectory
      .appending(path: "\(UUID().uuidString)-\(fileName)")
    try data.write(to: url, options: [.atomic])
    return url
  }

  private func temporaryOutputURL(fileExtension: String) -> URL {
    FileManager.default.temporaryDirectory
      .appending(path: "filtered-\(UUID().uuidString).\(fileExtension)")
  }

  private func fileName(from fileName: String, fileExtension: String) -> String {
    guard let dotIndex = fileName.lastIndex(of: ".") else {
      return "\(fileName).\(fileExtension)"
    }
    return "\(fileName[..<dotIndex]).\(fileExtension)"
  }
}
