import Foundation
import OSLog

actor LiveVideoPlayerService: VideoPlayerServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let tokenRefreshCoordinator: any TokenRefreshCoordinating
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "VideoPlayerAPI"
  )

  init(
    networkManager: any AuthenticatedNetworkManaging,
    tokenRefreshCoordinator: any TokenRefreshCoordinating = AppTokenRefreshCoordinator.shared,
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.networkManager = networkManager
    self.tokenRefreshCoordinator = tokenRefreshCoordinator
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

  func loadSubtitleCues(from url: URL) async throws -> [VideoSubtitleCue] {
    var request = URLRequest(url: url)
    request.setValue(Server.apiKey(), forHTTPHeaderField: "SeSACKey")
    if let authorization = try? await tokenRefreshCoordinator.authorizationHeaderValue() {
      request.setValue(authorization, forHTTPHeaderField: "Authorization")
    }

    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw VideoPlayerServiceError.invalidResponse
      }
      guard 200 ..< 300 ~= httpResponse.statusCode else {
        throw VideoPlayerServiceError.serverError
      }
      guard let string = String(data: data, encoding: .utf8) else {
        throw VideoPlayerServiceError.invalidResponse
      }
      return WebVTTSubtitleParser.parse(string)
    } catch let error as VideoPlayerServiceError {
      throw error
    } catch {
      Self.logger.error("❌ [VideoPlayerAPI] subtitle load failed error=\(String(describing: error), privacy: .public)")
      throw VideoPlayerServiceError.transport
    }
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
