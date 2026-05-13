import Foundation
import Testing
@testable import Oh_My_Filter

struct LiveCommunityServiceTests {
  @Test("post list request excludes geolocation query values")
  func postListExcludesGeolocationQueryValues() async throws {
    let manager = MockCommunityNetworkManager()
    let service = LiveCommunityService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.postPageData(nextCursor: "0"), statusCode: 200))
    _ = try await service.loadPosts(nextCursor: nil, limit: 10, orderBy: "createdAt")

    let capturedURLs = await manager.capturedURLs
    #expect(capturedURLs == ["http://filter.sesac.kr:42598/v1/posts/geolocation?limit=10&order_by=createdAt"])
    #expect(capturedURLs[0].contains("latitude") == false)
    #expect(capturedURLs[0].contains("longitude") == false)
    #expect(capturedURLs[0].contains("maxDistance") == false)
  }

  @Test("liked post request excludes geolocation and category query values")
  func likedPostsExcludeUnexpectedQueryValues() async throws {
    let manager = MockCommunityNetworkManager()
    let service = LiveCommunityService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.postPageData(nextCursor: "0"), statusCode: 200))
    _ = try await service.loadLikedPosts(nextCursor: "cursor-1", limit: 5)

    let capturedURLs = await manager.capturedURLs
    #expect(capturedURLs == ["http://filter.sesac.kr:42598/v1/posts/likes/me?limit=5&next=cursor-1"])
    #expect(capturedURLs[0].contains("latitude") == false)
    #expect(capturedURLs[0].contains("longitude") == false)
    #expect(capturedURLs[0].contains("maxDistance") == false)
    #expect(capturedURLs[0].contains("category") == false)
  }

  @Test("search and video routers use expected urls")
  func searchAndVideoUseExpectedURLs() async throws {
    let manager = MockCommunityNetworkManager()
    let service = LiveCommunityService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.postListData, statusCode: 200))
    await manager.enqueueResponse(NetworkResponse(data: Self.videoPageData(nextCursor: "0"), statusCode: 200))

    _ = try await service.searchPosts(title: "필터")
    _ = try await service.loadVideos(nextCursor: nil, limit: 8)

    #expect(await manager.capturedURLs == [
      "http://filter.sesac.kr:42598/v1/posts/search?title=%ED%95%84%ED%84%B0",
      "http://filter.sesac.kr:42598/v1/videos?limit=8",
    ])
  }

  @Test("post mutation APIs use expected urls and methods")
  func postMutationAPIsUseExpectedURLsAndMethods() async throws {
    let manager = MockCommunityNetworkManager()
    let service = LiveCommunityService(networkManager: manager)

    await manager.enqueueResponse(NetworkResponse(data: Self.postDetailData, statusCode: 200))
    await manager.enqueueResponse(NetworkResponse(data: Self.postDetailData, statusCode: 200))
    await manager.enqueueResponse(NetworkResponse(data: Data(#"{"like_status":true}"#.utf8), statusCode: 200))
    await manager.enqueueResponse(NetworkResponse(data: Self.commentData, statusCode: 200))
    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 200))

    let draft = CommunityPostDraft(category: "보정", title: "제목", content: "내용")
    _ = try await service.createPost(draft: draft, newImages: [])
    _ = try await service.updatePost(postID: "post-1", draft: draft, newImages: [])
    _ = try await service.toggleLike(postID: "post-1", status: true)
    _ = try await service.createComment(postID: "post-1", parentCommentID: nil, content: "댓글")
    try await service.deletePost(postID: "post-1")

    #expect(await manager.capturedURLs == [
      "http://filter.sesac.kr:42598/v1/posts",
      "http://filter.sesac.kr:42598/v1/posts/post-1",
      "http://filter.sesac.kr:42598/v1/posts/post-1/like",
      "http://filter.sesac.kr:42598/v1/posts/post-1/comments",
      "http://filter.sesac.kr:42598/v1/posts/post-1",
    ])
    #expect(await manager.capturedMethods == ["POST", "PUT", "POST", "POST", "DELETE"])
  }

  @Test("service maps 400 and decode failure")
  func mapsErrors() async {
    let invalidRequestManager = MockCommunityNetworkManager()
    let invalidRequestService = LiveCommunityService(networkManager: invalidRequestManager)
    await invalidRequestManager.enqueueResponse(NetworkResponse(data: Data(#"{"message":"bad"}"#.utf8), statusCode: 400))

    do {
      _ = try await invalidRequestService.loadPosts(nextCursor: nil, limit: 10, orderBy: "createdAt")
      Issue.record("Expected invalid request")
    } catch let error as CommunityServiceError {
      #expect(error == .invalidRequestMessage("bad"))
    } catch {
      Issue.record("Unexpected error: \(error)")
    }

    let decodeManager = MockCommunityNetworkManager()
    let decodeService = LiveCommunityService(networkManager: decodeManager)
    await decodeManager.enqueueResponse(NetworkResponse(data: Data(#"{}"#.utf8), statusCode: 200))

    do {
      _ = try await decodeService.loadVideos(nextCursor: nil, limit: 10)
      Issue.record("Expected invalid response")
    } catch let error as CommunityServiceError {
      #expect(error == .invalidResponse)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

private actor MockCommunityNetworkManager: AuthenticatedNetworkManaging {
  private var queuedResults: [Result<NetworkResponse, Error>] = []
  private(set) var capturedURLs: [String] = []
  private(set) var capturedMethods: [String] = []

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
    capturedURLs.append(capturedURL(router: router, parameters: parameters))
    capturedMethods.append(router.method.rawValue)
    return try nextResult()
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(capturedURL(router: router, parameters: parameters))
    capturedMethods.append(router.method.rawValue)
    _ = try? JSONEncoder().encode(body)
    return try nextResult()
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    multipartFiles: [MultipartFilePart],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedURLs.append(capturedURL(router: router, parameters: parameters))
    capturedMethods.append(router.method.rawValue)
    return try nextResult()
  }

  private func capturedURL<Router: ApiRouter>(router: Router, parameters: RequestQuery) -> String {
    guard parameters.isEmpty == false,
          var components = URLComponents(string: router.url) else {
      return router.url
    }

    components.queryItems = parameters.urlQueryItems
    return components.url?.absoluteString ?? router.url
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }

    return try queuedResults.removeFirst().get()
  }
}

private extension LiveCommunityServiceTests {
  static func postPageData(nextCursor: String) -> Data {
    Data(
      """
      {
        "data": [
          {
            "post_id": "post-1",
            "category": "핫스팟",
            "title": "제목",
            "content": "내용",
            "creator": {"user_id": "user-1", "nick": "sesac", "hashTags": []},
            "files": [],
            "is_like": false,
            "like_count": 1,
            "createdAt": "2024-07-21T14:00:00.000Z",
            "updatedAt": "2024-07-21T15:30:00.000Z"
          }
        ],
        "next_cursor": "\(nextCursor)"
      }
      """.utf8
    )
  }

  static let postListData = Data(
    """
    {
      "data": []
    }
    """.utf8
  )

  static func videoPageData(nextCursor: String) -> Data {
    Data(
      """
      {
        "data": [],
        "next_cursor": "\(nextCursor)"
      }
      """.utf8
    )
  }

  static let postDetailData = Data(
    """
    {
      "post_id": "post-1",
      "category": "보정",
      "title": "제목",
      "content": "내용",
      "creator": {"user_id": "user-1", "nick": "sesac", "hashTags": []},
      "files": [],
      "is_like": false,
      "like_count": 1,
      "comments": [],
      "createdAt": "2024-07-21T14:00:00.000Z",
      "updatedAt": "2024-07-21T15:30:00.000Z"
    }
    """.utf8
  )

  static let commentData = Data(
    """
    {
      "comment_id": "comment-1",
      "content": "댓글",
      "createdAt": "2024-07-21T14:00:00.000Z",
      "creator": {"user_id": "user-1", "nick": "sesac", "hashTags": []}
    }
    """.utf8
  )
}
