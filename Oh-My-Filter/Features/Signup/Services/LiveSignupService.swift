import Foundation

struct LiveSignupService: SignupServicing {
  private let networkManager: any BaseNetworkManaging

  init(networkManager: any BaseNetworkManaging = BaseNetworkManager()) {
    self.networkManager = networkManager
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

  func join(request: SignupRequest) async throws {
    let response: NetworkResponse

    do {
      response = try await networkManager.request(UserApiRouter.signUp, body: request)
    } catch let error as NetworkError {
      throw mappedServiceError(error)
    }

    switch response.statusCode {
    case 200 ..< 300:
      return
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
