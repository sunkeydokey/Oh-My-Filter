import Foundation

struct LiveSignupService: SignupServicing {
  private let networkManager: any BaseNetworkManaging
  private let tokenStore: any AuthTokenStoring
  private let decoder: JSONDecoder
  private let now: @Sendable () -> Date

  init(
    networkManager: any BaseNetworkManaging = BaseNetworkManager(),
    tokenStore: any AuthTokenStoring = KeychainAuthTokenStore(),
    decoder: JSONDecoder = JSONDecoder(),
    now: @escaping @Sendable () -> Date = { .now }
  ) {
    self.networkManager = networkManager
    self.tokenStore = tokenStore
    self.decoder = decoder
    self.now = now
  }

  func validateEmail(_ email: String) async throws -> EmailValidationStatus {
    let response: NetworkResponse

    do {
      response = try await networkManager.request(
        UserApiRouter.validate,
        body: EmailValidationRequest(email: email)
      )
    } catch let error as NetworkError {
      throw mappedServiceError(error)
    }

    switch response.statusCode {
    case 200 ..< 300:
      return .available
    case 400:
      return .invalid
    case 409:
      return .duplicate
    default:
      throw SignupServiceError.serverError
    }
  }

  func join(request: SignupRequest) async throws -> LoginSession {
    let response: NetworkResponse

    do {
      response = try await networkManager.request(UserApiRouter.signUp, body: request)
    } catch let error as NetworkError {
      throw mappedServiceError(error)
    }

    switch response.statusCode {
    case 200 ..< 300:
      do {
        let decodedResponse = try decoder.decode(LoginResponseDTO.self, from: response.data)
        try await tokenStore.save(decodedResponse.tokenPayload(now: now()))
        return decodedResponse.session
      } catch {
        throw SignupServiceError.invalidResponse
      }
    case 400:
      throw SignupServiceError.invalidRequest
    case 409:
      throw SignupServiceError.duplicateEmail
    default:
      throw SignupServiceError.serverError
    }
  }

  private func mappedServiceError(_ error: NetworkError) -> SignupServiceError {
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
