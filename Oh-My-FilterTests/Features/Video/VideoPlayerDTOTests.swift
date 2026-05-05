import Foundation
import Testing
@testable import Oh_My_Filter

struct VideoPlayerDTOTests {
  private var decoder: JSONDecoder {
    let d = JSONDecoder()
    d.keyDecodingStrategy = .convertFromSnakeCase
    return d
  }

  @Test("video stream decodes and maps qualities and subtitles")
  func decodeVideoStream() throws {
    let dto = try decoder.decode(VideoStreamDTO.self, from: Self.streamData)
    let stream = dto.toDomain()

    #expect(dto.videoId == "video-1")
    #expect(stream.qualities.count == 2)
    #expect(stream.qualities[0].label == "1080p")
    #expect(stream.qualities[1].label == "720p")
    #expect(stream.subtitles.count == 1)
    #expect(stream.subtitles[0].language == "ko")
    #expect(stream.subtitles[0].isDefault == true)
  }

  @Test("stream url maps via AuthenticatedRemoteImageSupport")
  func streamURLMaps() throws {
    let dto = try decoder.decode(VideoStreamDTO.self, from: Self.streamData)
    let stream = dto.toDomain()

    #expect(stream.streamURL?.absoluteString.contains("/videos/stream/video-1/master.m3u8") == true)
    #expect(stream.qualities[0].url?.absoluteString.contains("/videos/stream/video-1/1080p/index.m3u8") == true)
  }

  @Test("like response decodes like_status")
  func decodeLikeResponse() throws {
    let liked = try decoder.decode(VideoLikeResponseDTO.self, from: Data(#"{"like_status":true}"#.utf8))
    let unliked = try decoder.decode(VideoLikeResponseDTO.self, from: Data(#"{"like_status":false}"#.utf8))

    #expect(liked.likeStatus == true)
    #expect(unliked.likeStatus == false)
  }
}

private extension VideoPlayerDTOTests {
  static let streamData = Data(
    """
    {
      "video_id": "video-1",
      "stream_url": "/videos/stream/video-1/master.m3u8?token=abc",
      "qualities": [
        { "quality": "1080p", "url": "/videos/stream/video-1/1080p/index.m3u8?token=abc" },
        { "quality": "720p",  "url": "/videos/stream/video-1/720p/index.m3u8?token=abc" }
      ],
      "subtitles": [
        { "language": "ko", "name": "한국어", "is_default": true, "url": "/videos/stream/video-1/subtitles/ko" }
      ]
    }
    """.utf8
  )
}
