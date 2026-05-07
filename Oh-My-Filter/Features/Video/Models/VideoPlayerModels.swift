import Foundation

nonisolated struct VideoStream: Sendable {
  let videoId: String
  let streamURL: URL?
  let qualities: [VideoQuality]
  let subtitles: [VideoSubtitle]
}

nonisolated struct VideoQuality: Identifiable, Equatable, Sendable {
  let label: String
  let url: URL?

  var id: String { label }
}

nonisolated struct VideoSubtitle: Sendable {
  let language: String
  let name: String
  let isDefault: Bool
  let url: URL?
}

nonisolated struct VideoSubtitleCue: Equatable, Sendable {
  let startTime: Double
  let endTime: Double
  let text: String
}
