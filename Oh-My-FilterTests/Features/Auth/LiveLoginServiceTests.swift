import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct LiveLoginServiceTests {
  @Test("login uses signIn router and forwards request body")
  func requestUsesSignInRouter() async throws {
    let manager = MockLoginNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = LiveLoginService(networkManager: manager, tokenStore: tokenStore)
    let request = LoginRequest(email: "sesac@sesac.com", password: "password123!")

    await manager.enqueueResponse(
      NetworkResponse(data: Self.successData, statusCode: 200)
    )

    _ = try await service.login(request: request)

    let capturedRequest = await manager.capturedBodyRequest
    if case .signIn? = capturedRequest?.router {
      #expect(Bool(true))
    } else {
      Issue.record("Expected signIn router")
    }
    #expect(capturedRequest?.loginBody == request)
  }

  @Test("Kakao login uses kakaoLogin router and forwards request body")
  func kakaoLoginRequestUsesKakaoRouter() async throws {
    let manager = MockLoginNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = LiveLoginService(networkManager: manager, tokenStore: tokenStore)
    let request = KakaoLoginRequest(oauthToken: "kakao-access-token")

    await manager.enqueueResponse(
      NetworkResponse(data: Self.successData, statusCode: 200)
    )

    _ = try await service.loginWithKakao(request: request)

    let capturedRequest = await manager.capturedBodyRequest
    if case .kakaoLogin? = capturedRequest?.router {
      #expect(Bool(true))
    } else {
      Issue.record("Expected kakaoLogin router")
    }
    #expect(capturedRequest?.kakaoBody == request)
  }

  @Test("Apple login uses appleLogin router and forwards request body")
  func appleLoginRequestUsesAppleRouter() async throws {
    let manager = MockLoginNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = LiveLoginService(networkManager: manager, tokenStore: tokenStore)
    let request = AppleLoginRequest(idToken: "apple-id-token")

    await manager.enqueueResponse(
      NetworkResponse(data: Self.successData, statusCode: 200)
    )

    _ = try await service.loginWithApple(request: request)

    let capturedRequest = await manager.capturedBodyRequest
    if case .appleLogin? = capturedRequest?.router {
      #expect(Bool(true))
    } else {
      Issue.record("Expected appleLogin router")
    }
    #expect(capturedRequest?.appleBody == request)
  }

  @Test("200 response decodes login session")
  func successResponseDecodesSession() async throws {
    let manager = MockLoginNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    let service = LiveLoginService(
      networkManager: manager,
      tokenStore: tokenStore,
      now: { now }
    )

    await manager.enqueueResponse(
      NetworkResponse(data: Self.successData, statusCode: 200)
    )

    let response = try await service.login(
      request: LoginRequest(email: "sesac@sesac.com", password: "password123!")
    )

    #expect(response == .fixture)

    let tokens = await tokenStore.savedTokens
    #expect(tokens?.accessToken == "access-token")
    #expect(tokens?.refreshToken == "refresh-token")
    #expect(tokens?.accessTokenExpiresAt == now.addingTimeInterval(5 * 60))
    #expect(tokens?.refreshTokenExpiresAt == now.addingTimeInterval(12_000 * 60))
  }

  @Test("400 response maps to invalid request message")
  func invalidRequestMapsMessage() async {
    let manager = MockLoginNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = LiveLoginService(networkManager: manager, tokenStore: tokenStore)

    await manager.enqueueResponse(
      NetworkResponse(data: Self.invalidRequestData, statusCode: 400)
    )

    do {
      _ = try await service.login(
        request: LoginRequest(email: "sesac@sesac.com", password: "")
      )
      Issue.record("Expected invalid request error")
    } catch {
      #expect(error as? LoginServiceError == .invalidRequest("필수값을 채워주세요."))
    }
  }

  @Test("401 response maps to unauthorized message")
  func unauthorizedMapsMessage() async {
    let manager = MockLoginNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = LiveLoginService(networkManager: manager, tokenStore: tokenStore)

    await manager.enqueueResponse(
      NetworkResponse(data: Self.unauthorizedData, statusCode: 401)
    )

    do {
      _ = try await service.login(
        request: LoginRequest(email: "sesac@sesac.com", password: "password123!")
      )
      Issue.record("Expected unauthorized error")
    } catch {
      #expect(error as? LoginServiceError == .unauthorized("계정을 확인해주세요."))
    }
  }

  @Test("network failures map to login service errors")
  func networkFailuresMapToServiceErrors() async {
    let manager = MockLoginNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = LiveLoginService(networkManager: manager, tokenStore: tokenStore)

    await manager.enqueueFailure(NetworkError.transport)

    do {
      _ = try await service.login(
        request: LoginRequest(email: "sesac@sesac.com", password: "password123!")
      )
      Issue.record("Expected transport error")
    } catch {
      #expect(error as? LoginServiceError == .transport)
    }
  }
}

private actor MockAuthTokenStore: AuthTokenStoring {
  private(set) var savedTokens: StoredAuthTokens?

  func save(_ tokens: StoredAuthTokens) async throws {
    savedTokens = tokens
  }

  func tokens() async throws -> StoredAuthTokens? {
    savedTokens
  }

  func delete() async throws {
    savedTokens = nil
  }
}

private actor MockLoginNetworkManager: BaseNetworkManaging {
  struct BodyRequest: Sendable {
    let router: UserApiRouter
    let loginBody: LoginRequest?
    let kakaoBody: KakaoLoginRequest?
    let appleBody: AppleLoginRequest?
  }

  private var queuedResults: [Result<NetworkResponse, Error>] = []
  private(set) var capturedBodyRequest: BodyRequest?

  func enqueueResponse(_ response: NetworkResponse) {
    queuedResults.append(.success(response))
  }

  func enqueueFailure(_ error: Error) {
    queuedResults.append(.failure(error))
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try nextResult()
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    if let loginRouter = router as? UserApiRouter {
      capturedBodyRequest = BodyRequest(
        router: loginRouter,
        loginBody: body as? LoginRequest,
        kakaoBody: body as? KakaoLoginRequest,
        appleBody: body as? AppleLoginRequest
      )
    }

    return try nextResult()
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }

    return try queuedResults.removeFirst().get()
  }
}

private extension LiveLoginServiceTests {
  static let successData = Data(
    """
    {
      "user_id": "66115b1197488f90d3e7e6e5",
      "email": "sesac@sesac.com",
      "nick": "새싹이Abc12",
      "profileImage": "/data/profiles/1712413657554.png",
      "accessToken": "access-token",
      "refreshToken": "refresh-token"
    }
    """.utf8
  )

  static let invalidRequestData = Data(
    """
    {
      "message": "필수값을 채워주세요."
    }
    """.utf8
  )

  static let unauthorizedData = Data(
    """
    {
      "message": "계정을 확인해주세요."
    }
    """.utf8
  )
}

private extension LoginSession {
  static let fixture = LoginSession(
    userID: "66115b1197488f90d3e7e6e5",
    email: "sesac@sesac.com",
    nick: "새싹이Abc12",
    profileImage: "/data/profiles/1712413657554.png"
  )
}
