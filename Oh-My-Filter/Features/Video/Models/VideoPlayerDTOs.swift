import Foundation

nonisolated struct VideoStreamDTO: Codable, Sendable {
  let videoId: String
  let streamUrl: String
  let qualities: [VideoStreamQualityDTO]
  let subtitles: [VideoSubtitleDTO]

  nonisolated func toDomain() -> VideoStream {
    VideoStream(
      videoId: videoId,
      streamURL: AuthenticatedRemoteImageSupport.url(from: streamUrl),
      qualities: qualities.map(\.toDomain),
      subtitles: subtitles.map(\.toDomain)
    )
  }
}

nonisolated struct VideoStreamQualityDTO: Codable, Sendable {
  let quality: String
  let url: String

  nonisolated var toDomain: VideoQuality {
    VideoQuality(label: quality, url: AuthenticatedRemoteImageSupport.url(from: url))
  }
}

nonisolated struct VideoSubtitleDTO: Codable, Sendable {
  let language: String
  let name: String
  let isDefault: Bool
  let url: String

  nonisolated var toDomain: VideoSubtitle {
    VideoSubtitle(
      language: language,
      name: name,
      isDefault: isDefault,
      url: AuthenticatedRemoteImageSupport.url(from: url)
    )
  }
}

nonisolated struct VideoLikeResponseDTO: Codable, Sendable {
  let likeStatus: Bool
}

nonisolated struct VideoLikeRequestBody: Encodable, Sendable {
  let likeStatus: Bool
}
