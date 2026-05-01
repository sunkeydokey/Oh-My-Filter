import Foundation

nonisolated enum ImageUploadPreset: Equatable, Sendable {
  case chat
  case profile
  case filter

  var maxCount: Int {
    switch self {
    case .chat:
      5
    case .profile:
      1
    case .filter:
      2
    }
  }

  var maxBytes: Int {
    switch self {
    case .chat:
      1_000_000
    case .profile:
      512_000
    case .filter:
      2_000_000
    }
  }

  var jpegQualityRange: ClosedRange<Double> {
    0.35...0.9
  }

  var multipartFieldName: String {
    "files"
  }

  var maximumSelectionMessage: String {
    "최대 \(maxCount)장까지 업로드할 수 있습니다."
  }
}
