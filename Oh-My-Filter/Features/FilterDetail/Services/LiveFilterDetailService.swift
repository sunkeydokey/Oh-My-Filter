import Foundation
import OSLog

actor LiveFilterDetailService: FilterDetailServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let sharedCommentService: any SharedCommentServicing
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "FilterDetailAPI"
  )

  init(
    networkManager: any AuthenticatedNetworkManaging,
    decoder: JSONDecoder = JSONDecoder(),
    sharedCommentService: (any SharedCommentServicing)? = nil
  ) {
    self.networkManager = networkManager
    self.sharedCommentService = sharedCommentService ?? LiveSharedCommentService(networkManager: networkManager, decoder: decoder)
    let configuredDecoder = decoder
    configuredDecoder.keyDecodingStrategy = .convertFromSnakeCase
    self.decoder = configuredDecoder
  }

  @MainActor
  init(decoder: JSONDecoder = JSONDecoder()) {
    self.init(networkManager: AuthenticatedNetworkManager(), decoder: decoder)
  }

  func loadFilterDetail(filterID: String) async throws -> FilterDetail {
    let router = FilterApiRouter.detail(filterID: filterID)
    let response: NetworkResponse
    do {
      response = try await networkManager.request(router)
    } catch let error as NetworkError {
      Self.logger.error("❌ [FilterDetailAPI] transport failed \(String(describing: error), privacy: .public)")
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [FilterDetailAPI] unexpected failure \(String(describing: error), privacy: .public)")
      throw FilterDetailServiceError.transport
    }

    switch response.statusCode {
    case 200 ..< 300:
      do {
        let dto = try decoder.decode(FilterResponseDTO.self, from: response.data)
        print(dto)
        return dto.toDomain()
      } catch {
        Self.logger.error("❌ [FilterDetailAPI] decode failed \(String(describing: error), privacy: .public)")
        throw FilterDetailServiceError.invalidResponse
      }
    default:
      Self.logger.error("❌ [FilterDetailAPI] server status=\(response.statusCode, privacy: .public)")
      throw FilterDetailServiceError.serverError
    }
  }

  func createComment(filterID: String, parentCommentID: String?, content: String) async throws -> CommentReply {
    guard filterID.isEmpty == false else {
      throw FilterDetailServiceError.invalidResponse
    }

    do {
      return try await sharedCommentService.createComment(
        router: FilterApiRouter.createComment(filterID: filterID),
        parentCommentID: parentCommentID,
        content: content
      )
    } catch let error as SharedCommentServiceError {
      throw mappedCommentError(error)
    }
  }

  private func mappedNetworkError(_ error: NetworkError) -> FilterDetailServiceError {
    switch error {
    case .invalidRequest, .invalidResponse:
      .invalidResponse
    case .transport:
      .transport
    }
  }

  private func mappedCommentError(_ error: SharedCommentServiceError) -> FilterDetailServiceError {
    switch error {
    case .invalidRequest, .invalidResponse:
      .invalidResponse
    case .notFound, .permissionDenied, .serverError:
      .serverError
    case .transport:
      .transport
    }
  }
}

private extension FilterResponseDTO {
  nonisolated func toDomain() -> FilterDetail {
    let fallbackCreator = FilterDetailCreator(
      id: creator?.userId ?? "",
      nick: creator?.nick ?? "알 수 없음",
      name: creator?.name,
      profileImageURL: AuthenticatedRemoteImageSupport.url(from: creator?.profileImage),
      introduction: creator?.introduction,
      hashTags: creator?.hashTags ?? []
    )

    return FilterDetail(
      id: filterId,
      title: title,
      category: category,
      introduction: introduction,
      description: description ?? "",
      originalImageURL: AuthenticatedRemoteImageSupport.url(from: files.first),
      fallbackFilteredImageURL: AuthenticatedRemoteImageSupport.url(from: files.dropFirst().first),
      creator: fallbackCreator,
      metadata: metadata?.toDomain() ?? FilterDetailMetadata(
        camera: nil,
        lens: nil,
        focalLength: nil,
        aperture: nil,
        shutterSpeed: nil,
        iso: nil
      ),
      filterValues: filterValues?.toDomain() ?? .neutral,
      comments: comments.map { $0.toDomain() },
      isDownloaded: isDownloaded,
      isLiked: isLiked,
      likeCount: likeCount,
      buyerCount: buyerCount,
      price: price,
      hashTags: hashTags.isEmpty ? fallbackCreator.hashTags : hashTags,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

private extension FilterMetadataDTO {
  nonisolated func toDomain() -> FilterDetailMetadata {
    FilterDetailMetadata(
      camera: camera,
      lens: lens,
      focalLength: focalLength,
      aperture: aperture,
      shutterSpeed: shutterSpeed,
      iso: iso
    )
  }
}

private extension FilterValuesDTO {
  nonisolated func toDomain() -> FilterValues {
    FilterValues(
      brightness: brightness ?? FilterValues.neutral.brightness,
      contrast: contrast ?? FilterValues.neutral.contrast,
      saturation: saturation ?? FilterValues.neutral.saturation,
      exposure: exposure ?? FilterValues.neutral.exposure,
      sharpen: sharpness ?? sharpen ?? FilterValues.neutral.sharpen,
      blur: blur ?? FilterValues.neutral.blur,
      vignette: vignette ?? FilterValues.neutral.vignette,
      noiseReduction: noiseReduction ?? FilterValues.neutral.noiseReduction,
      highlights: highlights ?? FilterValues.neutral.highlights,
      shadows: shadows ?? FilterValues.neutral.shadows,
      temperature: temperature ?? FilterValues.neutral.temperature,
      blackPoint: blackPoint ?? FilterValues.neutral.blackPoint
    )
  }
}
