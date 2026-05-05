import Foundation
import Testing
@testable import Oh_My_Filter

struct LiveVideoPlayerServiceTests {
  @Test("stream request uses video_id in url path")
  func streamRequestURL() async throws {
    let manager = MockVideoPlayerNetworkManager()
    let service = LiveVideoPlayerService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.streamData, statusCode: 200))
    _ = try await service.loadStream(videoId: "abc123")

    let captured = await manager.capturedURLs
    #expect(captured == ["http://filter.sesac.kr:42598/v1/videos/abc123/stream"])
  }

  @Test("like request uses video_id in url path")
  func likeRequestURL() async throws {
    let manager = MockVideoPlayerNetworkManager()
    let service = LiveVideoPlayerService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Data(#"{"like_status":true}"#.utf8), statusCode: 200))
    _ = try await service.toggleLike(videoId: "abc123", status: true)

    let captured = await manager.capturedURLs
    #expect(captured == ["http://filter.sesac.kr:42598/v1/videos/abc123/like"])
  }

  @Test("404 maps to notFound error")
  func notFoundMapsCorrectly() async {
    let manager = MockVideoPlayerNetworkManager()
    let service = LiveVideoPlayerService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Data(#"{"message":"not found"}"#.utf8), statusCode: 404))

    do {
      _ = try await service.loadStream(videoId: "missing")
      Issue.record("Expected notFound error")
    } catch let error as VideoPlayerServiceError {
      #expect(error == .notFound)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test("decode failure maps to invalidResponse")
  func invalidResponseMapsCorrectly() async {
    let manager = MockVideoPlayerNetworkManager()
    let service = LiveVideoPlayerService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Data(#"{}"#.utf8), statusCode: 200))

    do {
      _ = try await service.loadStream(videoId: "video-1")
      Issue.record("Expected invalidResponse error")
    } catch let error as VideoPlayerServiceError {
      #expect(error == .invalidResponse)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

private actor MockVideoPlayerNetworkManager: AuthenticatedNetworkManaging {
  private var queuedResults: [Result<NetworkResponse, Error>] = []
  private(set) var capturedURLs: [String] = []

  func enqueueResponse(_ response: NetworkResponse) {
    queuedResults.append(.success(response))
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(router.url)
    return try nextResult()
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(router.url)
    return try nextResult()
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }
    return try queuedResults.removeFirst().get()
  }
}

private extension LiveVideoPlayerServiceTests {
  static let streamData = Data(
    """
    {
      "video_id": "abc123",
      "stream_url": "/videos/stream/abc123/master.m3u8?token=tok",
      "qualities": [
        { "quality": "1080p", "url": "/videos/stream/abc123/1080p/index.m3u8?token=tok" }
      ],
      "subtitles": []
    }
    """.utf8
  )
}
