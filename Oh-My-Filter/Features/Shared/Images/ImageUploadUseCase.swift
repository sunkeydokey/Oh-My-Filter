import Foundation

nonisolated protocol ImageUploadUseCase: Sendable {
  func multipartFiles(
    from selections: [PhotoPickerUploadSelection],
    preset: ImageUploadPreset
  ) throws -> [MultipartFilePart]
}

nonisolated struct LiveImageUploadUseCase: ImageUploadUseCase {
  private let compressionUseCase: any ImageCompressionUseCase

  init(compressionUseCase: any ImageCompressionUseCase = LiveImageCompressionUseCase()) {
    self.compressionUseCase = compressionUseCase
  }

  func multipartFiles(
    from selections: [PhotoPickerUploadSelection],
    preset: ImageUploadPreset
  ) throws -> [MultipartFilePart] {
    try selections.prefix(preset.maxCount).map { selection in
      let data = try compressionUseCase.jpegData(from: selection.data, preset: preset)
      return MultipartFilePart(
        fieldName: preset.multipartFieldName,
        fileName: selection.fileName,
        mimeType: "image/jpeg",
        data: data
      )
    }
  }
}
