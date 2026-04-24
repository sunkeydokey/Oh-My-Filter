import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct LiveLoginServiceTests {
  @Test("login uses signIn router and forwards request body")
  func requestUsesSignInRouter() async throws {
    let manager = MockLoginNetworkManager()
    let service = LiveLoginService(networkManager: manager)
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
    #expect(capturedRequest?.body == request)
  }

  @Test("200 response decodes login session")
  func successResponseDecodesSession() async throws {
    let manager = MockLoginNetworkManager()
    let service = LiveLoginService(networkManager: manager)

    await manager.enqueueResponse(
      NetworkResponse(data: Self.successData, statusCode: 200)
    )

    let response = try await service.login(
      request: LoginRequest(email: "sesac@sesac.com", password: "password123!")
    )

    #expect(response == .fixture)
  }

  @Test("400 response maps to invalid request message")
  func invalidRequestMapsMessage() async {
    let manager = MockLoginNetworkManager()
    let service = LiveLoginService(networkManager: manager)

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
    let service = LiveLoginService(networkManager: manager)

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
    let service = LiveLoginService(networkManager: manager)

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

private actor MockLoginNetworkManager: BaseNetworkManaging {
  struct BodyRequest: Sendable {
    let router: UserApiRouter
    let body: LoginRequest
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
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try nextResult()
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    if let loginRouter = router as? UserApiRouter,
       let loginBody = body as? LoginRequest {
      capturedBodyRequest = BodyRequest(router: loginRouter, body: loginBody)
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
    profileImage: "/data/profiles/1712413657554.png",
    accessToken: "access-token",
    refreshToken: "refresh-token"
  )
}
