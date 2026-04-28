import Foundation

struct LiveLoginService: LoginServicing {
  private let networkManager: any BaseNetworkManaging
  private let tokenStore: any AuthTokenStoring
  private let decoder: JSONDecoder
  private let now: @Sendable () -> Date

  init(
    networkManager: any BaseNetworkManaging,
    tokenStore: any AuthTokenStoring,
    decoder: JSONDecoder = JSONDecoder(),
    now: @escaping @Sendable () -> Date = { .now }
  ) {
    self.networkManager = networkManager
    self.tokenStore = tokenStore
    self.decoder = decoder
    self.now = now
  }

  @MainActor
  init(
    decoder: JSONDecoder = JSONDecoder(),
    now: @escaping @Sendable () -> Date = { .now }
  ) {
    self.init(
      networkManager: BaseNetworkManager(),
      tokenStore: KeychainAuthTokenStore(),
      decoder: decoder,
      now: now
    )
  }

  func login(request: LoginRequest) async throws -> LoginSession {
    try await performLogin(router: UserApiRouter.signIn, body: request)
  }

  func loginWithKakao(request: KakaoLoginRequest) async throws -> LoginSession {
    try await performLogin(router: UserApiRouter.kakaoLogin, body: request)
  }

  private func performLogin<Body: Encodable>(
    router: UserApiRouter,
    body: Body
  ) async throws -> LoginSession {
    let response: NetworkResponse

    do {
      response = try await networkManager.request(router, body: body)
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
        try await tokenStore.save(decodedResponse.tokenPayload(now: now()))
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
    case 409:
      throw mappedServerMessageError(
        data: response.data,
        fallback: .conflict("이미 가입된 유저입니다.")
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
    case .conflict:
      return .conflict(payload.message)
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

private struct LoginErrorResponseDTO: Codable, Sendable {
  let message: String
}
