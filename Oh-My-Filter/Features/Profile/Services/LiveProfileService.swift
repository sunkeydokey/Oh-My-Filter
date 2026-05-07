import Foundation
import OSLog

nonisolated struct LiveProfileService: ProfileServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "ProfileAPI"
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

  func loadMyProfile() async throws -> MyProfile {
    let response = try await request(UserApiRouter.getOwnProfile)
    guard 200 ..< 300 ~= response.statusCode else {
      throw ProfileServiceError.serverError
    }

    do {
      return try decoder.decode(MyProfileResponseDTO.self, from: response.data).toDomain()
    } catch {
      Self.logger.error("Profile decode failed: \(String(describing: error), privacy: .public)")
      throw ProfileServiceError.invalidResponse
    }
  }

  func updateProfile(request: ProfileUpdateRequest) async throws -> MyProfile {
    let response = try await networkManager.request(UserApiRouter.editUserProfile, body: request)
    switch response.statusCode {
    case 200 ..< 300:
      do {
        return try decoder.decode(MyProfileResponseDTO.self, from: response.data).toDomain()
      } catch {
        Self.logger.error("Profile update decode failed: \(String(describing: error), privacy: .public)")
        throw ProfileServiceError.invalidResponse
      }
    case 400:
      throw ProfileServiceError.invalidRequest
    default:
      throw ProfileServiceError.serverError
    }
  }

  func uploadProfileImage(multipartFiles: [MultipartFilePart]) async throws -> String? {
    let response = try await networkManager.request(
      UserApiRouter.uploadProfileImage,
      multipartFiles: multipartFiles
    )
    switch response.statusCode {
    case 200 ..< 300:
      do {
        return try decoder.decode(ProfileImageUploadResponse.self, from: response.data).profileImage
      } catch {
        Self.logger.error("Profile image decode failed: \(String(describing: error), privacy: .public)")
        throw ProfileServiceError.invalidResponse
      }
    case 400:
      throw ProfileServiceError.invalidRequest
    default:
      throw ProfileServiceError.uploadFailed
    }
  }

  private func request<Router: ApiRouter>(_ router: Router) async throws -> NetworkResponse {
    do {
      return try await networkManager.request(router)
    } catch let error as NetworkError {
      throw mappedNetworkError(error)
    } catch {
      throw ProfileServiceError.transport
    }
  }

  private func mappedNetworkError(_ error: NetworkError) -> ProfileServiceError {
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

private extension MyProfileResponseDTO {
  nonisolated func toDomain() -> MyProfile {
    MyProfile(
      userID: userId,
      email: email,
      nick: nick,
      name: name,
      introduction: introduction,
      profileImage: profileImage,
      phoneNumber: phoneNum,
      hashTags: hashTags
    )
  }
}
