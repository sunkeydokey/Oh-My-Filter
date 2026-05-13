import AVFoundation
import Foundation

nonisolated protocol MOVToMP4ConversionUseCase: Sendable {
  func mp4Data(from movData: Data) async throws -> Data
}

nonisolated enum VideoConversionError: Error, Equatable, Sendable {
  case exportFailed(String)
  case sessionCreationFailed
  case noOutputFile
}

nonisolated struct LiveMOVToMP4ConversionUseCase: MOVToMP4ConversionUseCase {
  func mp4Data(from movData: Data) async throws -> Data {
    let tempDir = FileManager.default.temporaryDirectory
    let inputURL = tempDir.appending(path: "\(UUID().uuidString).mov")
    let outputURL = tempDir.appending(path: "\(UUID().uuidString).mp4")

    try movData.write(to: inputURL)
    defer { try? FileManager.default.removeItem(at: inputURL) }

    let asset = AVURLAsset(url: inputURL)
    guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
      throw VideoConversionError.sessionCreationFailed
    }

    defer { try? FileManager.default.removeItem(at: outputURL) }

    try await session.export(to: outputURL, as: .mp4)

    guard FileManager.default.fileExists(atPath: outputURL.path()) else {
      throw VideoConversionError.noOutputFile
    }

    return try Data(contentsOf: outputURL)
  }
}
