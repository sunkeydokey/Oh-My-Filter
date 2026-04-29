import Foundation

nonisolated struct BaseNetworkManager: BaseNetworkManaging {
  private let session: URLSession
  private let encoder: JSONEncoder

  init(
    session: URLSession = .shared,
    encoder: JSONEncoder = JSONEncoder(),
    tokenStore: any AuthTokenStoring
  ) {
    self.session = session
    self.encoder = encoder
  }

  @MainActor
  init(
    session: URLSession = .shared,
    encoder: JSONEncoder = JSONEncoder()
  ) {
    self.init(
      session: session,
      encoder: encoder,
      tokenStore: KeychainAuthTokenStore()
    )
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try await performRequest(router: router, headers: headers, parameters: parameters, body: nil)
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    headers: [String: String],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    let requestBody: Data

    do {
      requestBody = try encoder.encode(body)
    } catch {
      throw NetworkError.invalidRequest
    }

    return try await performRequest(
      router: router,
      headers: headers,
      parameters: parameters,
      body: requestBody
    )
  }

  private func performRequest<Router: ApiRouter>(
    router: Router,
    headers: [String: String],
    parameters: RequestQuery,
    body: Data?
  ) async throws -> NetworkResponse {
    let request = try await makeRequest(router: router, headers: headers, parameters: parameters, body: body)

    do {
      let (data, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
      }

      return NetworkResponse(data: data, statusCode: httpResponse.statusCode)
    } catch let error as NetworkError {
      throw error
    } catch {
      throw NetworkError.transport
    }
  }

  private func makeRequest<Router: ApiRouter>(
    router: Router,
    headers: [String: String],
    parameters: RequestQuery,
    body: Data?
  ) async throws -> URLRequest {
    guard var components = URLComponents(string: router.url),
          let baseURL = components.url else {
      throw NetworkError.invalidRequest
    }

    if parameters.isEmpty == false {
      components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) ?? components
      components.queryItems = parameters.urlQueryItems
    }

    guard let url = components.url else {
      throw NetworkError.invalidRequest
    }

    var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
    request.httpMethod = router.method.rawValue
    request.setValue(router.contentType.rawValue, forHTTPHeaderField: "Content-Type")
    request.setValue(ContentType.json.rawValue, forHTTPHeaderField: "Accept")
    request.setValue(Server.apiKey(), forHTTPHeaderField: "SeSACKey")
    for (field, value) in headers {
      request.setValue(value, forHTTPHeaderField: field)
    }
    request.httpBody = body
    return request
  }
}
