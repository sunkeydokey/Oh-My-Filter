import Foundation

nonisolated protocol AuthenticatedNetworkManaging: Sendable {
  func request<Router: ApiRouter>(
    _ router: Router,
    parameters: RequestQuery
  ) async throws -> NetworkResponse

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse

  func request<Router: ApiRouter>(
    _ router: Router,
    multipartFiles: [MultipartFilePart],
    parameters: RequestQuery
  ) async throws -> NetworkResponse
}

extension AuthenticatedNetworkManaging {
  func request<Router: ApiRouter>(
    _ router: Router,
    multipartFiles: [MultipartFilePart],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    throw NetworkError.invalidRequest
  }

  func request<Router: ApiRouter>(_ router: Router) async throws -> NetworkResponse {
    try await request(router, parameters: .empty)
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body
  ) async throws -> NetworkResponse {
    try await request(router, body: body, parameters: .empty)
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    multipartFiles: [MultipartFilePart]
  ) async throws -> NetworkResponse {
    try await request(router, multipartFiles: multipartFiles, parameters: .empty)
  }
}

enum AuthenticatedNetworkError: Error, Equatable, Sendable {
  case missingAccessToken
  case refreshFailed
  case sessionExpired
}
