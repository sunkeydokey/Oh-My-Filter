import Foundation

nonisolated protocol BaseNetworkManaging: Sendable {
  func request<Router: ApiRouter>(
    _ router: Router,
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse

  func request<Router: ApiRouter>(
    _ router: Router,
    multipartFiles: [MultipartFilePart],
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse
}

extension BaseNetworkManaging {
  func request<Router: ApiRouter>(
    _ router: Router,
    multipartFiles: [MultipartFilePart],
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    throw NetworkError.invalidRequest
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try await request(router, headers: [:], parameters: parameters)
  }

  func request<Router: ApiRouter>(_ router: Router) async throws -> NetworkResponse {
    try await request(router, headers: [:], parameters: .empty)
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body
  ) async throws -> NetworkResponse {
    try await request(router, body: body, headers: [:], parameters: .empty)
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try await request(router, body: body, headers: [:], parameters: parameters)
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    multipartFiles: [MultipartFilePart]
  ) async throws -> NetworkResponse {
    try await request(router, multipartFiles: multipartFiles, headers: [:], parameters: .empty)
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    multipartFiles: [MultipartFilePart],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try await request(router, multipartFiles: multipartFiles, headers: [:], parameters: parameters)
  }
}
