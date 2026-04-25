import Foundation
import OSLog

struct LiveMainService: MainServicing {
  private let networkManager: any BaseNetworkManaging
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "MainAPI"
  )

  init(
    networkManager: any BaseNetworkManaging,
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.networkManager = networkManager
    let configuredDecoder = decoder
    configuredDecoder.keyDecodingStrategy = .convertFromSnakeCase
    self.decoder = configuredDecoder
  }

  @MainActor
  init(decoder: JSONDecoder = JSONDecoder()) {
    self.init(networkManager: BaseNetworkManager(), decoder: decoder)
  }

  func loadTodayFilter() async throws -> MainTodayFilter {
    Self.logger.debug("➡️ [MainAPI] GET \(HomeApiRouter.todayFilter.url, privacy: .public) started")
    let response = try await request(HomeApiRouter.todayFilter)
    Self.logger.debug("⬅️ [MainAPI] GET \(HomeApiRouter.todayFilter.url, privacy: .public) status=\(response.statusCode, privacy: .public)")

    switch response.statusCode {
    case 200 ..< 300:
      do {
        let dto = try decoder.decode(MainTodayFilterDTO.self, from: response.data)
        Self.logger.debug("✅ [MainAPI] GET \(HomeApiRouter.todayFilter.url, privacy: .public) decoded successfully")
        return dto.toDomain()
      } catch {
        Self.logger.error("❌ [MainAPI] GET \(HomeApiRouter.todayFilter.url, privacy: .public) decode failed: \(String(describing: error), privacy: .public) body=\(Self.responseBodyDescription(response.data), privacy: .public)")
        throw MainServiceError.invalidResponse
      }
    default:
      Self.logger.error("❌ [MainAPI] GET \(HomeApiRouter.todayFilter.url, privacy: .public) server error body=\(Self.responseBodyDescription(response.data), privacy: .public)")
      throw MainServiceError.serverError
    }
  }

  func loadMainBanners() async throws -> [MainBanner] {
    Self.logger.debug("➡️ [MainAPI] GET \(HomeApiRouter.mainBanners.url, privacy: .public) started")
    let response = try await request(HomeApiRouter.mainBanners)
    Self.logger.debug("⬅️ [MainAPI] GET \(HomeApiRouter.mainBanners.url, privacy: .public) status=\(response.statusCode, privacy: .public)")

    switch response.statusCode {
    case 200 ..< 300:
      do {
        let dto = try decoder.decode(MainBannersResponseDTO.self, from: response.data)
        let dtos = dto.data
        Self.logger.debug("✅ [MainAPI] GET \(HomeApiRouter.mainBanners.url, privacy: .public) decoded successfully count=\(dtos.count, privacy: .public)")
        return dtos.map { $0.toDomain() }
      } catch {
        Self.logger.error("❌ [MainAPI] GET \(HomeApiRouter.mainBanners.url, privacy: .public) decode failed: \(String(describing: error), privacy: .public) body=\(Self.responseBodyDescription(response.data), privacy: .public)")
        throw MainServiceError.invalidResponse
      }
    default:
      Self.logger.error("❌ [MainAPI] GET \(HomeApiRouter.mainBanners.url, privacy: .public) server error body=\(Self.responseBodyDescription(response.data), privacy: .public)")
      throw MainServiceError.serverError
    }
  }

  func loadHotTrendFilters() async throws -> [MainHotTrendFilter] {
    Self.logger.debug("➡️ [MainAPI] GET \(HomeApiRouter.hotTrendFilters.url, privacy: .public) started")
    let response = try await request(HomeApiRouter.hotTrendFilters)
    Self.logger.debug("⬅️ [MainAPI] GET \(HomeApiRouter.hotTrendFilters.url, privacy: .public) status=\(response.statusCode, privacy: .public)")

    switch response.statusCode {
    case 200 ..< 300:
      do {
        let dto = try decoder.decode(MainHotTrendFiltersResponseDTO.self, from: response.data)
        let dtos = dto.data
        Self.logger.debug("✅ [MainAPI] GET \(HomeApiRouter.hotTrendFilters.url, privacy: .public) decoded successfully count=\(dtos.count, privacy: .public)")
        return dtos.map { $0.toDomain() }
      } catch {
        Self.logger.error("❌ [MainAPI] GET \(HomeApiRouter.hotTrendFilters.url, privacy: .public) decode failed: \(String(describing: error), privacy: .public) body=\(Self.responseBodyDescription(response.data), privacy: .public)")
        throw MainServiceError.invalidResponse
      }
    default:
      Self.logger.error("❌ [MainAPI] GET \(HomeApiRouter.hotTrendFilters.url, privacy: .public) server error body=\(Self.responseBodyDescription(response.data), privacy: .public)")
      throw MainServiceError.serverError
    }
  }

  func loadTodayAuthor() async throws -> MainTodayAuthor {
    Self.logger.debug("➡️ [MainAPI] GET \(UserApiRouter.getTodayAuthorInfo.url, privacy: .public) started")
    let response = try await request(UserApiRouter.getTodayAuthorInfo)
    Self.logger.debug("⬅️ [MainAPI] GET \(UserApiRouter.getTodayAuthorInfo.url, privacy: .public) status=\(response.statusCode, privacy: .public)")

    switch response.statusCode {
    case 200 ..< 300:
      do {
        let dto = try decoder.decode(MainTodayAuthorResponseDTO.self, from: response.data)
        let decodedMessage = "✅ [MainAPI] GET \(UserApiRouter.getTodayAuthorInfo.url) decoded successfully author.userId=\(dto.author.userId) author.nick=\(dto.author.nick) author.profileImage=\(dto.author.profileImage ?? "<nil>") author.introduction=\(dto.author.introduction ?? "<nil>")"
        Self.logger.debug("\(decodedMessage, privacy: .public)")

        let author = dto.author.toDomain()
        let mappedMessage = "✅ [MainAPI] GET \(UserApiRouter.getTodayAuthorInfo.url) mapped to domain userID=\(author.userID) nick=\(author.nick) profileImageUrl=\(author.profileImageUrl?.absoluteString ?? "<nil>") introduction=\(author.introduction ?? "<nil>")"
        Self.logger.debug("\(mappedMessage, privacy: .public)")
        return author
      } catch {
        Self.logger.error("❌ [MainAPI] GET \(UserApiRouter.getTodayAuthorInfo.url, privacy: .public) decode failed: \(String(describing: error), privacy: .public) body=\(Self.responseBodyDescription(response.data), privacy: .public)")
        throw MainServiceError.invalidResponse
      }
    default:
      Self.logger.error("❌ [MainAPI] GET \(UserApiRouter.getTodayAuthorInfo.url, privacy: .public) server error body=\(Self.responseBodyDescription(response.data), privacy: .public)")
      throw MainServiceError.serverError
    }
  }

  private func request<Router: ApiRouter>(_ router: Router) async throws -> NetworkResponse {
    do {
      Self.logger.debug("↗️ [MainAPI] request router=\(router.url, privacy: .public)")
      return try await networkManager.request(router)
    } catch let error as NetworkError {
      Self.logger.error("❌ [MainAPI] transport failed router=\(router.url, privacy: .public) networkError=\(String(describing: error), privacy: .public)")
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [MainAPI] unexpected failure router=\(router.url, privacy: .public) error=\(String(describing: error), privacy: .public)")
      throw MainServiceError.transport
    }
  }

  private static func responseBodyDescription(_ data: Data) -> String {
    guard let body = String(data: data, encoding: .utf8), body.isEmpty == false else {
      return "<empty>"
    }

    return body
  }

  private func mappedNetworkError(_ error: NetworkError) -> MainServiceError {
    switch error {
    case .invalidRequest, .invalidResponse:
      .invalidResponse
    case .transport:
      .transport
    }
  }
}

private extension MainTodayFilterDTO {
  func toDomain() -> MainTodayFilter {
    MainTodayFilter(
      id: filterId,
      title: title,
      subtitle: introduction ?? description,
      imageUrl: AuthenticatedRemoteImageSupport.url(from: files.first),
      creatorName: creator?.nick,
      creatorProfileImageUrl: AuthenticatedRemoteImageSupport.url(from: creator?.profileImage)
    )
  }
}

private extension MainBannerDTO {
  func toDomain() -> MainBanner {
    MainBanner(
      id: name,
      title: name,
      subtitle: "",
      imageUrl: AuthenticatedRemoteImageSupport.url(from: imageUrl)
    )
  }
}

private extension MainHotTrendFilterDTO {
  func toDomain() -> MainHotTrendFilter {
    MainHotTrendFilter(
      id: filterId,
      title: title,
      imageUrl: AuthenticatedRemoteImageSupport.url(from: files.first),
      creatorName: creator?.nick,
      creatorProfileImageUrl: AuthenticatedRemoteImageSupport.url(from: creator?.profileImage)
    )
  }
}

private extension MainTodayAuthorDTO {
  func toDomain() -> MainTodayAuthor {
    MainTodayAuthor(
      userID: userId,
      nick: nick,
      profileImageUrl: AuthenticatedRemoteImageSupport.url(from: profileImage),
      introduction: introduction
    )
  }
}
