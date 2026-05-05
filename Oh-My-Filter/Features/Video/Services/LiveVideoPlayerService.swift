import Foundation
import OSLog

actor LiveVideoPlayerService: VideoPlayerServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "VideoPlayerAPI"
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

  func loadStream(videoId: String) async throws -> VideoStream {
    guard videoId.isEmpty == false else { throw VideoPlayerServiceError.invalidRequest }

    let response = try await request(VideoApiRouter.stream(videoId: videoId), parameters: .empty)
    return try decode(VideoStreamDTO.self, from: response).toDomain()
  }

  func toggleLike(videoId: String, status: Bool) async throws -> Bool {
    guard videoId.isEmpty == false else { throw VideoPlayerServiceError.invalidRequest }

    let body = VideoLikeRequestBody(like_status: status)
    let response = try await requestWithBody(VideoApiRouter.like(videoId: videoId), body: body, parameters: .empty)
    return try decode(VideoLikeResponseDTO.self, from: response).likeStatus
  }

  private func request<Router: ApiRouter>(_ router: Router, parameters: RequestQuery) async throws -> NetworkResponse {
    do {
      return try await networkManager.request(router, parameters: parameters)
    } catch let error as NetworkError {
      Self.logger.error("❌ [VideoPlayerAPI] transport failed error=\(String(describing: error), privacy: .public)")
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [VideoPlayerAPI] unexpected failure error=\(String(describing: error), privacy: .public)")
      throw VideoPlayerServiceError.transport
    }
  }

  private func requestWithBody<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    do {
      return try await networkManager.request(router, body: body, parameters: parameters)
    } catch let error as NetworkError {
      Self.logger.error("❌ [VideoPlayerAPI] transport failed error=\(String(describing: error), privacy: .public)")
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [VideoPlayerAPI] unexpected failure error=\(String(describing: error), privacy: .public)")
      throw VideoPlayerServiceError.transport
    }
  }

  private func decode<DTO: Decodable>(_ type: DTO.Type, from response: NetworkResponse) throws -> DTO {
    switch response.statusCode {
    case 200 ..< 300:
      do {
        return try decoder.decode(type, from: response.data)
      } catch {
        Self.logger.error("❌ [VideoPlayerAPI] decode failed error=\(String(describing: error), privacy: .public)")
        throw VideoPlayerServiceError.invalidResponse
      }
    case 400:
      throw VideoPlayerServiceError.invalidRequest
    case 404:
      throw VideoPlayerServiceError.notFound
    default:
      throw VideoPlayerServiceError.serverError
    }
  }

  private func mappedNetworkError(_ error: NetworkError) -> VideoPlayerServiceError {
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
