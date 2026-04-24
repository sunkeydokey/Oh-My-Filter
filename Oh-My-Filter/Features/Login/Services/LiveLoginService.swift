import Foundation

struct LiveLoginService: LoginServicing {
  private let networkManager: any BaseNetworkManaging
  private let decoder: JSONDecoder

  init(
    networkManager: any BaseNetworkManaging = BaseNetworkManager(),
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.networkManager = networkManager
    self.decoder = decoder
  }

  func login(request: LoginRequest) async throws -> LoginSession {
    let response: NetworkResponse

    do {
      response = try await networkManager.request(UserApiRouter.signIn, body: request)
    } catch let error as LoginServiceError {
      throw error
    } catch let error as NetworkError {
      throw mappedNetworkError(error)
    } catch {
      throw LoginServiceError.transport
    }

    switch response.statusCode {
    case 200 ..< 300:
      do {
        let decodedResponse = try decoder.decode(LoginResponseDTO.self, from: response.data)
        return decodedResponse.session
      } catch {
        throw LoginServiceError.invalidResponse
      }
    case 400:
      throw mappedServerMessageError(
        data: response.data,
        fallback: .invalidRequest("필수값을 채워주세요.")
      )
    case 401:
      throw mappedServerMessageError(
        data: response.data,
        fallback: .unauthorized("계정을 확인해주세요.")
      )
    default:
      throw LoginServiceError.serverError
    }
  }

  private func mappedServerMessageError(
    data: Data,
    fallback: LoginServiceError
  ) -> LoginServiceError {
    guard
      let payload = try? decoder.decode(LoginErrorResponseDTO.self, from: data),
      payload.message.isEmpty == false
    else {
      return fallback
    }

    switch fallback {
    case .invalidRequest:
      return .invalidRequest(payload.message)
    case .unauthorized:
      return .unauthorized(payload.message)
    case .serverError, .invalidResponse, .transport:
      return fallback
    }
  }

  private func mappedNetworkError(_ error: NetworkError) -> LoginServiceError {
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

private struct LoginResponseDTO: Codable, Sendable {
  let userID: String
  let email: String
  let nick: String
  let profileImage: String?
  let accessToken: String
  let refreshToken: String

  enum CodingKeys: String, CodingKey {
    case userID = "user_id"
    case email
    case nick
    case profileImage
    case accessToken
    case refreshToken
  }

  var session: LoginSession {
    LoginSession(
      userID: userID,
      email: email,
      nick: nick,
      profileImage: profileImage,
      accessToken: accessToken,
      refreshToken: refreshToken
    )
  }
}

private struct LoginErrorResponseDTO: Codable, Sendable {
  let message: String
}
