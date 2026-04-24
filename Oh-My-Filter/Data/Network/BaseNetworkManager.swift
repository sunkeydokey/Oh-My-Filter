import Foundation

struct BaseNetworkManager: BaseNetworkManaging {
  private let session: URLSession
  private let encoder: JSONEncoder

  init(
    session: URLSession = .shared,
    encoder: JSONEncoder = JSONEncoder()
  ) {
    self.session = session
    self.encoder = encoder
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try await performRequest(router: router, parameters: parameters, body: nil)
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    let requestBody: Data

    do {
      requestBody = try encoder.encode(body)
    } catch {
      throw NetworkError.invalidRequest
    }

    return try await performRequest(router: router, parameters: parameters, body: requestBody)
  }

  private func performRequest<Router: ApiRouter>(
    router: Router,
    parameters: RequestQuery,
    body: Data?
  ) async throws -> NetworkResponse {
    let request = try makeRequest(router: router, parameters: parameters, body: body)

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
    parameters: RequestQuery,
    body: Data?
  ) throws -> URLRequest {
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

    var request = URLRequest(url: url)
    request.httpMethod = router.method.rawValue
    request.setValue(router.contentType.rawValue, forHTTPHeaderField: "Content-Type")
    request.setValue(ContentType.json.rawValue, forHTTPHeaderField: "Accept")
    request.setValue(Server.apiKey(), forHTTPHeaderField: "SeSACKey")
    request.httpBody = body
    return request
  }
}
