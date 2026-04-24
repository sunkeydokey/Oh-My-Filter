import Foundation
import Testing
@testable import Oh_My_Filter

struct LiveSignupServiceTests {
  @Test("email validation maps status codes to domain states")
  func validateEmailMapsStatusCodes() async throws {
    let manager = MockBaseNetworkManager()
    let service = await LiveSignupService(networkManager: manager)

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
    let service = await LiveSignupService(networkManager: manager)
    let request = SignupRequest(email: "sesac@sesac.com", password: "1234Abcd!", nick: "새싹이")

    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 400))
    do {
      try await service.join(request: request)
      Issue.record("Expected invalidRequest error")
    } catch let error as SignupServiceError {
      #expect(error == .invalidRequest)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }

    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 409))
    do {
      try await service.join(request: request)
      Issue.record("Expected duplicateEmail error")
    } catch let error as SignupServiceError {
      #expect(error == .duplicateEmail)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  @Test("network failures map to signup service errors")
  func joinMapsNetworkFailures() async throws {
    let manager = MockBaseNetworkManager()
    let service = await LiveSignupService(networkManager: manager)
    let request = SignupRequest(email: "sesac@sesac.com", password: "1234Abcd!", nick: "새싹이")

    await manager.enqueueFailure(NetworkError.transport)

    do {
      try await service.join(request: request)
      Issue.record("Expected transport error")
    } catch let error as SignupServiceError {
      #expect(error == .transport)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }
}

private actor MockBaseNetworkManager: BaseNetworkManaging {
  private var queuedResults: [Result<NetworkResponse, Error>] = []

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
    try nextResult()
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }

    return try queuedResults.removeFirst().get()
  }
}
