import Foundation
import Testing
@testable import Oh_My_Filter

struct LiveSignupServiceTests {
  @Test("email validation maps status codes to domain states")
  func validateEmailMapsStatusCodes() async throws {
    let manager = MockBaseNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = await LiveSignupService(
      networkManager: manager,
      tokenStore: tokenStore,
      deviceTokenStore: MockDeviceTokenStore()
    )

    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 200))
    let available = try await service.validateEmail("sesac@sesac.com")
    #expect(available == .available)

    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 400))
    let invalid = try await service.validateEmail("sesac@sesac.com")
    #expect(invalid == .invalid)

    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 409))
    let duplicate = try await service.validateEmail("sesac@sesac.com")
    #expect(duplicate == .duplicate)
  }

  @Test("signup maps status codes to service errors")
  func joinMapsStatusCodes() async throws {
    let manager = MockBaseNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = await LiveSignupService(
      networkManager: manager,
      tokenStore: tokenStore,
      deviceTokenStore: MockDeviceTokenStore()
    )
    let request = SignupRequest(email: "sesac@sesac.com", password: "1234Abcd!", nick: "새싹이")

    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 400))
    do {
      _ = try await service.join(request: request)
      Issue.record("Expected invalidRequest error")
    } catch let error as SignupServiceError {
      #expect(error == .invalidRequest)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }

    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 409))
    do {
      _ = try await service.join(request: request)
      Issue.record("Expected duplicateEmail error")
    } catch let error as SignupServiceError {
      #expect(error == .duplicateEmail)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test("successful signup decodes session and stores tokens")
  func joinSuccessStoresTokens() async throws {
    let manager = MockBaseNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let now = Date(timeIntervalSinceReferenceDate: 1_000)
    let service = await LiveSignupService(
      networkManager: manager,
      tokenStore: tokenStore,
      deviceTokenStore: MockDeviceTokenStore(),
      now: { now }
    )
    let request = SignupRequest(email: "sesac@sesac.com", password: "1234Abcd!", nick: "새싹이")

    await manager.enqueueResponse(NetworkResponse(data: Self.successData, statusCode: 200))

    let session = try await service.join(request: request)

    #expect(session == .fixture)

    let tokens = await tokenStore.savedTokens
    #expect(tokens?.accessToken == "access-token")
    #expect(tokens?.refreshToken == "refresh-token")
    #expect(tokens?.accessTokenExpiresAt == now.addingTimeInterval(5 * 60))
    #expect(tokens?.refreshTokenExpiresAt == now.addingTimeInterval(12_000 * 60))
  }

  @Test("network failures map to signup service errors")
  func joinMapsNetworkFailures() async throws {
    let manager = MockBaseNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = await LiveSignupService(
      networkManager: manager,
      tokenStore: tokenStore,
      deviceTokenStore: MockDeviceTokenStore()
    )
    let request = SignupRequest(email: "sesac@sesac.com", password: "1234Abcd!", nick: "새싹이")

    await manager.enqueueFailure(NetworkError.transport)

    do {
      _ = try await service.join(request: request)
      Issue.record("Expected transport error")
    } catch let error as SignupServiceError {
      #expect(error == .transport)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test("signup injects stored device token")
  func joinInjectsStoredDeviceToken() async throws {
    let manager = MockBaseNetworkManager()
    let tokenStore = MockAuthTokenStore()
    let service = await LiveSignupService(
      networkManager: manager,
      tokenStore: tokenStore,
      deviceTokenStore: MockDeviceTokenStore(token: "fcm-token")
    )

    await manager.enqueueResponse(NetworkResponse(data: Self.successData, statusCode: 200))

    _ = try await service.join(
      request: SignupRequest(email: "sesac@sesac.com", password: "1234Abcd!", nick: "새싹이")
    )

    #expect(await manager.capturedSignupBody?.deviceToken == "fcm-token")
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

private struct MockDeviceTokenStore: DeviceTokenStoring {
  let token: String?

  init(token: String? = nil) {
    self.token = token
  }

  func deviceToken() -> String? {
    token
  }

  func saveDeviceToken(_ token: String) {}
}

private extension LiveSignupServiceTests {
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
}

private extension LoginSession {
  static let fixture = LoginSession(
    userID: "66115b1197488f90d3e7e6e5",
    email: "sesac@sesac.com",
    nick: "새싹이Abc12",
    profileImage: "/data/profiles/1712413657554.png"
  )
}

private actor MockBaseNetworkManager: BaseNetworkManaging {
  private var queuedResults: [Result<NetworkResponse, Error>] = []
  private(set) var capturedSignupBody: SignupRequest?

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
    capturedSignupBody = body as? SignupRequest
    return try nextResult()
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }

    return try queuedResults.removeFirst().get()
  }
}
