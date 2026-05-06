import Foundation
import Testing
@testable import Oh_My_Filter

struct FilterDetailServiceTests {
  @Test("detail endpoint uses /filters/{filter_id}")
  func detailEndpointUsesFilterID() {
    #expect(EndPoint.Filters.detail(filterID: "filter-123") == "http://filter.sesac.kr:42598/v1/filters/filter-123")
  }

  @Test("detail service requests and decodes nested payload")
  func detailServiceDecodesPayload() async throws {
    let manager = MockFilterDetailNetworkManager()
    let service = LiveFilterDetailService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.detailData, statusCode: 200))
    let detail = try await service.loadFilterDetail(filterID: "filter-123")

    #expect(await manager.capturedURLs == ["http://filter.sesac.kr:42598/v1/filters/filter-123"])
    #expect(detail.id == "filter-123")
    #expect(detail.title == "청록새록")
    #expect(detail.metadata.camera == "Apple iPhone 16 Pro")
    #expect(detail.metadata.lens == "와이드 카메라")
    #expect(detail.metadata.focalLength == "50 mm")
    #expect(detail.metadata.aperture == "f/4")
    #expect(detail.metadata.iso == "100")
    #expect(detail.filterValues.brightness == 0.12)
    #expect(detail.creator.nick == "SESAC YOON")
    #expect(detail.comments.first?.replies.first?.content == "저도 좋아요")
    #expect(detail.isDownloaded == false)
  }

  @Test("optional metadata fields decode safely")
  func optionalMetadataDecodesSafely() throws {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let dto = try decoder.decode(FilterResponseDTO.self, from: Self.minimumDetailData)

    #expect(dto.photoMetadata?.camera == "iPhone")
    #expect(dto.photoMetadata?.lensInfo == nil)
    #expect(dto.comments.isEmpty)
  }

  @Test("filter comment creation uses filter comment endpoint")
  func filterCommentCreationUsesEndpoint() async throws {
    let manager = MockFilterDetailNetworkManager()
    let service = LiveFilterDetailService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.commentData, statusCode: 200))
    let comment = try await service.createComment(filterID: "filter-123", parentCommentID: nil, content: "댓글")

    #expect(await manager.capturedURLs == ["http://filter.sesac.kr:42598/v1/filters/filter-123/comments"])
    #expect(comment.content == "댓글")
    #expect(comment.creator.nick == "sesac")
  }

  @Test("current user id loads from own profile endpoint")
  func currentUserIDLoadsFromOwnProfileEndpoint() async throws {
    let manager = MockFilterDetailNetworkManager()
    let service = LiveFilterDetailService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.ownProfileData, statusCode: 200))
    let currentUserID = try await service.loadCurrentUserID()

    #expect(await manager.capturedURLs == ["http://filter.sesac.kr:42598/v1/users/me/profile"])
    #expect(currentUserID == "user-1")
  }

  @Test("network failures map to transport")
  func networkFailuresMapToTransport() async {
    let manager = MockFilterDetailNetworkManager()
    let service = LiveFilterDetailService(networkManager: manager)

    await manager.enqueueFailure(NetworkError.transport)

    do {
      _ = try await service.loadFilterDetail(filterID: "filter-123")
      Issue.record("Expected transport error")
    } catch let error as FilterDetailServiceError {
      #expect(error == .transport)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test("decode failures map to invalid response")
  func decodeFailuresMapToInvalidResponse() async {
    let manager = MockFilterDetailNetworkManager()
    let service = LiveFilterDetailService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Data("[]".utf8), statusCode: 200))

    do {
      _ = try await service.loadFilterDetail(filterID: "filter-123")
      Issue.record("Expected invalid response")
    } catch let error as FilterDetailServiceError {
      #expect(error == .invalidResponse)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test("server failures map to server error")
  func serverFailuresMapToServerError() async {
    let manager = MockFilterDetailNetworkManager()
    let service = LiveFilterDetailService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 500))

    do {
      _ = try await service.loadFilterDetail(filterID: "filter-123")
      Issue.record("Expected server error")
    } catch let error as FilterDetailServiceError {
      #expect(error == .serverError)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

private actor MockFilterDetailNetworkManager: AuthenticatedNetworkManaging {
  private var queuedResults: [Result<NetworkResponse, Error>] = []
  private(set) var capturedURLs: [String] = []

  func enqueueResponse(_ response: NetworkResponse) {
    queuedResults.append(.success(response))
  }

  func enqueueFailure(_ error: Error) {
    queuedResults.append(.failure(error))
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

private extension FilterDetailServiceTests {
  static let detailData = Data(
    """
    {
      "data": {
        "filter_id": "filter-123",
        "category": "풍경",
        "title": "청록새록",
        "introduction": "맑은 청록빛",
        "description": "햇살 아래 돋아나는 새싹처럼 맑고 투명한 빛을 담은 필터입니다.",
        "files": ["/data/filters/original.jpg", "/data/filters/filtered.jpg"],
        "creator": {
          "user_id": "user-1",
          "nick": "SESAC YOON",
          "name": "윤새싹",
          "profileImage": "/data/profiles/user.jpg",
          "introduction": "자연의 색을 담습니다.",
          "hashTags": ["섬세함", "자연"]
        },
        "photoMetadata": {
          "camera": "Apple iPhone 16 Pro",
          "lens_info": "와이드 카메라",
          "focal_length": 50,
          "aperture": 4,
          "shutter_speed": "1/120",
          "iso": 100,
          "pixel_width": 8192,
          "pixel_height": 5464,
          "file_size": 25000000,
          "format": "JPEG",
          "date_time_original": "9999-10-20T15:30:00Z",
          "latitude": 37.51775,
          "longitude": 126.886557
        },
        "filter_values": {
          "brightness": 0.12,
          "contrast": 1.1,
          "saturation": 1.2,
          "exposure": 0.05,
          "sharpen": 0.2,
          "blur": 0,
          "vignette": 0.3,
          "noise_reduction": 0.1,
          "highlights": -0.1,
          "shadows": 0.2,
          "temperature": 200,
          "black_point": 0.05
        },
        "comments": [
          {
            "comment_id": "comment-1",
            "content": "색감이 좋아요",
            "user": { "user_id": "user-2", "nick": "andev", "profileImage": null },
            "createdAt": "2026-02-08T14:55:45.508Z",
            "replies": [
              {
                "reply_id": "reply-1",
                "content": "저도 좋아요",
                "user": { "user_id": "user-3", "nick": "crayon", "profileImage": null },
                "createdAt": "2026-02-08T15:55:45.508Z"
              }
            ]
          }
        ],
        "is_downloaded": false,
        "is_liked": true,
        "like_count": 800,
        "buyer_count": 2400,
        "price": 2000,
        "hash_tags": ["#섬세함", "#자연"],
        "createdAt": "2026-02-08T14:55:45.508Z",
        "updatedAt": "2026-02-08T14:55:45.508Z"
      }
    }
    """.utf8
  )

  static let minimumDetailData = Data(
    """
    {
      "filter_id": "filter-123",
      "title": "청록새록",
      "files": [],
      "photoMetadata": { "camera": "iPhone" }
    }
    """.utf8
  )

  static let commentData = Data(
    """
    {
      "comment_id": "comment-2",
      "content": "댓글",
      "createdAt": "2026-02-08T15:55:45.508Z",
      "creator": {
        "user_id": "user-2",
        "nick": "sesac",
        "hashTags": []
      }
    }
    """.utf8
  )

  static let ownProfileData = Data(
    """
    {
      "user_id": "user-1",
      "nick": "sesac"
    }
    """.utf8
  )
}
