import Foundation

nonisolated protocol ImageUploadUseCase: Sendable {
  func multipartFiles(
    from selections: [PhotoPickerUploadSelection],
    preset: ImageUploadPreset
  ) async throws -> [MultipartFilePart]
}

nonisolated struct LiveImageUploadUseCase: ImageUploadUseCase {
  private let compressionUseCase: any ImageCompressionUseCase
  private let movConversionUseCase: any MOVToMP4ConversionUseCase

  init(
    compressionUseCase: any ImageCompressionUseCase = LiveImageCompressionUseCase(),
    movConversionUseCase: any MOVToMP4ConversionUseCase = LiveMOVToMP4ConversionUseCase()
  ) {
    self.compressionUseCase = compressionUseCase
    self.movConversionUseCase = movConversionUseCase
  }

  func multipartFiles(
    from selections: [PhotoPickerUploadSelection],
    preset: ImageUploadPreset
  ) async throws -> [MultipartFilePart] {
    var parts: [MultipartFilePart] = []
    for selection in selections.prefix(preset.maxCount) {
      let data: Data
      let fileName: String
      let mimeType: String

      switch selection.mediaKind {
      case .image:
        data = try compressionUseCase.jpegData(from: selection.data, preset: preset)
        fileName = renamed(selection.fileName, extension: "jpg")
        mimeType = "image/jpeg"
      case .video:
        let videoData: Data
        if selection.fileName.lowercased().hasSuffix(".mov") {
          videoData = try await movConversionUseCase.mp4Data(from: selection.data)
        } else {
          videoData = selection.data
        }
        guard videoData.count <= preset.maxBytes else {
          throw ImageCompressionError.exceedsMaximumBytes
        }
        data = videoData
        fileName = renamed(selection.fileName, extension: "mp4")
        mimeType = "video/mp4"
      }

      parts.append(MultipartFilePart(
        fieldName: preset.multipartFieldName,
        fileName: fileName,
        mimeType: mimeType,
        data: data
      ))
    }
    return parts
  }

  private func renamed(_ fileName: String, extension ext: String) -> String {
    guard let dotIndex = fileName.lastIndex(of: ".") else {
      return "\(fileName).\(ext)"
    }
    return "\(fileName[..<dotIndex]).\(ext)"
  }
}
