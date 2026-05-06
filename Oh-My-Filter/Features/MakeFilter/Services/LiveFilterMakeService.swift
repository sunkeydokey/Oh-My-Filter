import Foundation
import OSLog

nonisolated struct LiveFilterMakeService: FilterMakeServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "FilterMakeAPI"
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

  func uploadFiles(_ files: [MultipartFilePart]) async throws -> [String] {
    let response = try await performRequest {
      try await networkManager.request(FilterApiRouter.uploadFiles, multipartFiles: files)
    }

    switch response.statusCode {
    case 200 ..< 300:
      do {
        return try decoder.decode(FileResponseDTO.self, from: response.data).files
      } catch {
        Self.logger.error("❌ [FilterMakeAPI] file decode failed \(String(describing: error), privacy: .public)")
        throw FilterMakeServiceError.invalidResponse
      }
    case 400:
      throw mappedServerMessageError(data: response.data)
    default:
      throw FilterMakeServiceError.serverError
    }
  }

  func createFilter(request: FilterMakeRequest) async throws -> FilterDetail {
    try await submit(router: .create, request: request)
  }

  func updateFilter(filterID: String, request: FilterMakeRequest) async throws -> FilterDetail {
    try await submit(router: .update(filterID: filterID), request: request)
  }

  private func submit(
    router: FilterApiRouter,
    request: FilterMakeRequest
  ) async throws -> FilterDetail {
    let response = try await performRequest {
      try await networkManager.request(router, body: request)
    }

    switch response.statusCode {
    case 200 ..< 300:
      do {
        return try decoder.decode(FilterResponseDTO.self, from: response.data).toDomainForFilterMake()
      } catch {
        Self.logger.error("❌ [FilterMakeAPI] filter decode failed \(String(describing: error), privacy: .public)")
        throw FilterMakeServiceError.invalidResponse
      }
    case 400:
      throw mappedServerMessageError(data: response.data)
    case 404:
      throw FilterMakeServiceError.filterNotFound
    case 445:
      throw FilterMakeServiceError.forbidden
    default:
      throw FilterMakeServiceError.serverError
    }
  }

  private func performRequest(_ operation: () async throws -> NetworkResponse) async throws -> NetworkResponse {
    do {
      return try await operation()
    } catch let error as NetworkError {
      throw mappedNetworkError(error)
    } catch let error as AuthenticatedNetworkError {
      throw error == .sessionExpired ? FilterMakeServiceError.serverError : .transport
    } catch let error as FilterMakeServiceError {
      throw error
    } catch {
      Self.logger.error("❌ [FilterMakeAPI] unexpected failure \(String(describing: error), privacy: .public)")
      throw FilterMakeServiceError.transport
    }
  }

  private func mappedServerMessageError(data: Data) -> FilterMakeServiceError {
    guard
      let payload = try? decoder.decode(FilterMakeErrorResponseDTO.self, from: data),
      payload.message.isEmpty == false
    else {
      return .invalidRequest("필수값을 채워주세요.")
    }

    return .invalidRequest(payload.message)
  }

  private func mappedNetworkError(_ error: NetworkError) -> FilterMakeServiceError {
    switch error {
    case .invalidRequest:
      .invalidRequest("필수값을 채워주세요.")
    case .invalidResponse:
      .invalidResponse
    case .transport:
      .transport
    }
  }
}

private nonisolated struct FilterMakeErrorResponseDTO: Decodable, Sendable {
  let message: String
}

private extension FilterResponseDTO {
  nonisolated func toDomainForFilterMake() -> FilterDetail {
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
      metadata: photoMetadata?.toDomainForFilterMake() ?? FilterDetailMetadata(
        camera: nil,
        lens: nil,
        focalLength: nil,
        aperture: nil,
        shutterSpeed: nil,
        iso: nil
      ),
      filterValues: filterValues?.toDomainForFilterMake() ?? .neutral,
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

private extension PhotoMetadataDTO {
  nonisolated func toDomainForFilterMake() -> FilterDetailMetadata {
    FilterDetailMetadata(
      camera: camera,
      lens: lensInfo,
      focalLength: focalLength.map { "\($0.formattedExifNumber) mm" },
      aperture: aperture.map { "f/\($0.formattedExifNumber)" },
      shutterSpeed: shutterSpeed,
      iso: iso?.formatted(.number)
    )
  }
}

private extension Double {
  nonisolated var formattedExifNumber: String {
    formatted(.number.precision(.fractionLength(0 ... 2)))
  }
}

private extension FilterValuesDTO {
  nonisolated func toDomainForFilterMake() -> FilterValues {
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
