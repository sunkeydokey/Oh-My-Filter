import Foundation
import UniformTypeIdentifiers

nonisolated enum PhotoPickerUploadMediaKind: Hashable, Sendable {
  case image
  case video

  var systemImage: String {
    switch self {
    case .image:
      "photo"
    case .video:
      "video"
    }
  }

  var defaultMimeType: String {
    switch self {
    case .image:
      "image/jpeg"
    case .video:
      "video/quicktime"
    }
  }

  var defaultFileExtension: String {
    switch self {
    case .image:
      "jpg"
    case .video:
      "mov"
    }
  }
}

nonisolated struct PhotoPickerUploadSelection: Hashable, Identifiable, Sendable {
  let id: UUID
  let data: Data
  let fileName: String
  let mediaKind: PhotoPickerUploadMediaKind
  let mimeType: String

  init(
    id: UUID = UUID(),
    data: Data,
    fileName: String,
    mediaKind: PhotoPickerUploadMediaKind = .image,
    mimeType: String? = nil
  ) {
    self.id = id
    self.data = data
    self.fileName = fileName
    self.mediaKind = mediaKind
    self.mimeType = mimeType ?? mediaKind.defaultMimeType
  }
}

extension PhotoPickerUploadSelection {
  init(
    id: UUID = UUID(),
    data: Data,
    baseName: String,
    mediaKind: PhotoPickerUploadMediaKind,
    preferredType: UTType?
  ) {
    let fileExtension = preferredType?.preferredFilenameExtension ?? mediaKind.defaultFileExtension
    let mimeType = preferredType?.preferredMIMEType ?? mediaKind.defaultMimeType
    self.init(
      id: id,
      data: data,
      fileName: "\(baseName).\(fileExtension)",
      mediaKind: mediaKind,
      mimeType: mimeType
    )
  }
}
