import Foundation
import OSLog

actor LiveCommunityService: CommunityServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "CommunityAPI"
  )

  init(
    networkManager: any AuthenticatedNetworkManaging,
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.networkManager = networkManager
    let configuredDecoder = decoder
    configuredDecoder.keyDecodingStrategy = .convertFromSnakeCase
    self.decoder = configuredDecoder
  }

  @MainActor
  init(decoder: JSONDecoder = JSONDecoder()) {
    self.init(networkManager: AuthenticatedNetworkManager(), decoder: decoder)
  }

  func loadPosts(nextCursor: String?, limit: Int, orderBy: String) async throws -> CommunityPostPage {
    guard limit > 0 else { throw CommunityServiceError.invalidRequest }

    let response = try await request(
      CommunityApiRouter.posts,
      parameters: pageQuery(nextCursor: nextCursor, limit: limit, extra: ["order_by": orderBy])
    )
    return try decode(CommunityPostPageDTO.self, from: response).toDomain()
  }

  func searchPosts(title: String) async throws -> [CommunityPost] {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let response = try await request(
      CommunityApiRouter.searchPosts,
      parameters: trimmedTitle.isEmpty ? .empty : RequestQuery(["title": trimmedTitle])
    )
    return try decode(CommunityPostListDTO.self, from: response).toDomain()
  }

  func loadLikedPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage {
    guard limit > 0 else { throw CommunityServiceError.invalidRequest }

    let response = try await request(
      CommunityApiRouter.likedPosts,
      parameters: pageQuery(nextCursor: nextCursor, limit: limit)
    )
    return try decode(CommunityPostPageDTO.self, from: response).toDomain()
  }

  func loadPostDetail(postID: String) async throws -> CommunityPost {
    guard postID.isEmpty == false else { throw CommunityServiceError.invalidRequest }

    let response = try await request(CommunityApiRouter.postDetail(postID: postID), parameters: .empty)
    return try decode(CommunityPostDTO.self, from: response).toDomain()
  }

  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage {
    guard limit > 0 else { throw CommunityServiceError.invalidRequest }

    let response = try await request(VideoApiRouter.list, parameters: pageQuery(nextCursor: nextCursor, limit: limit))
    return try decode(CommunityVideoPageDTO.self, from: response).toDomain()
  }

  private func request<Router: ApiRouter>(_ router: Router, parameters: RequestQuery) async throws -> NetworkResponse {
    do {
      return try await networkManager.request(router, parameters: parameters)
    } catch let error as NetworkError {
      Self.logger.error("❌ [CommunityAPI] transport failed error=\(String(describing: error), privacy: .public)")
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [CommunityAPI] unexpected failure error=\(String(describing: error), privacy: .public)")
      throw CommunityServiceError.transport
    }
  }

  private func decode<DTO: Decodable>(_ type: DTO.Type, from response: NetworkResponse) throws -> DTO {
    switch response.statusCode {
    case 200 ..< 300:
      do {
        return try decoder.decode(type, from: response.data)
      } catch {
        Self.logger.error("❌ [CommunityAPI] decode failed error=\(String(describing: error), privacy: .public)")
        throw CommunityServiceError.invalidResponse
      }
    case 400:
      throw CommunityServiceError.invalidRequest
    case 404:
      throw CommunityServiceError.notFound
    default:
      throw CommunityServiceError.serverError
    }
  }

  private func pageQuery(
    nextCursor: String?,
    limit: Int,
    extra: [String: String] = [:]
  ) -> RequestQuery {
    var values = extra
    values["limit"] = String(limit)

    if let nextCursor, nextCursor.isEmpty == false {
      values["next"] = nextCursor
    }

    return RequestQuery(values)
  }

  private func mappedNetworkError(_ error: NetworkError) -> CommunityServiceError {
    switch error {
    case .invalidRequest:
      .invalidRequest
    case .invalidResponse:
      .invalidResponse
    case .transport:
      .transport
    }
  }
}
