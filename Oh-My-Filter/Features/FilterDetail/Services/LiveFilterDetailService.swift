import Foundation
import OSLog

actor LiveFilterDetailService: FilterDetailServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "FilterDetailAPI"
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

  func loadFilterDetail(filterID: String) async throws -> FilterDetail {
    let router = FilterApiRouter.detail(filterID: filterID)
    Self.logger.debug("➡️ [FilterDetailAPI] GET \(router.url, privacy: .public) started")

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

  private func mappedNetworkError(_ error: NetworkError) -> FilterDetailServiceError {
    switch error {
    case .invalidRequest, .invalidResponse:
      .invalidResponse
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
      sharpen: sharpen ?? FilterValues.neutral.sharpen,
      blur: blur ?? FilterValues.neutral.blur,
      vignette: vignette ?? FilterValues.neutral.vignette,
      noiseReduction: noiseReduction ?? FilterValues.neutral.noiseReduction,
      highlights: highlights ?? FilterValues.neutral.highlights,
      shadows: shadows ?? FilterValues.neutral.shadows,
      temperature: temperature ?? FilterValues.neutral.temperature,
      tint: tint ?? FilterValues.neutral.tint,
      blackPoint: blackPoint ?? FilterValues.neutral.blackPoint
    )
  }
}

private extension FilterCommentDTO {
  nonisolated func toDomain() -> FilterDetailComment {
    FilterDetailComment(
      id: commentId,
      user: user.toCommentUser(),
      content: content,
      createdAt: createdAt,
      replies: replies.map { $0.toDomain() }
    )
  }
}

private extension FilterReplyDTO {
  nonisolated func toDomain() -> FilterDetailReply {
    FilterDetailReply(
      id: replyId,
      user: user.toCommentUser(),
      content: content,
      createdAt: createdAt
    )
  }
}

private extension Optional where Wrapped == FilterDetailUserDTO {
  nonisolated func toCommentUser() -> FilterDetailCommentUser {
    FilterDetailCommentUser(
      id: self?.userId ?? "",
      nick: self?.nick ?? "알 수 없음",
      profileImageURL: AuthenticatedRemoteImageSupport.url(from: self?.profileImage)
    )
  }
}
