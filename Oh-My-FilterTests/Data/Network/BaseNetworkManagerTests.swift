import Foundation
import Testing
@testable import Oh_My_Filter

@Suite(.serialized)
@MainActor
struct BaseNetworkManagerTests {
  @Test("body request uses router metadata and encodes JSON payload")
  func requestWithBodyBuildsExpectedURLRequest() async throws {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      #expect(request.url?.absoluteString == "https://example.com/users/join")
      #expect(request.httpMethod == HttpMethod.post.rawValue)
      #expect(request.value(forHTTPHeaderField: "Content-Type") == ContentType.json.rawValue)
      #expect(request.value(forHTTPHeaderField: "Accept") == ContentType.json.rawValue)

      let body = try #require(requestBodyData(from: request))
      let payload = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
      #expect(payload["email"] == "sesac@sesac.com")
      #expect(payload["password"] == "1234Abcd!")
      #expect(payload["nick"] == "새싹이")

      return TestURLProtocol.StubResponse(statusCode: 200)
    }

    let response = try await manager.request(
      TestRouter.join,
      body: SignupRequest(email: "sesac@sesac.com", password: "1234Abcd!", nick: "새싹이")
    )

    #expect(response.statusCode == 200)
  }

  @Test("param request appends sorted query items")
  func requestWithParametersBuildsQueryString() async throws {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      #expect(request.url?.absoluteString == "https://example.com/users/search?nick=sesac&page=1")
      #expect(request.httpMethod == HttpMethod.get.rawValue)
      #expect(request.httpBody == nil)
      return TestURLProtocol.StubResponse(statusCode: 200)
    }

    let response = try await manager.request(
      TestRouter.search,
      parameters: ["page": "1", "nick": "sesac"]
    )

    #expect(response.statusCode == 200)
  }

  @Test("request applies custom headers")
  func requestAppliesCustomHeaders() async throws {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      #expect(request.value(forHTTPHeaderField: "RefreshToken") == "refresh-token")
      return TestURLProtocol.StubResponse(statusCode: 200)
    }

    let response = try await manager.request(
      TestRouter.search,
      headers: ["RefreshToken": "refresh-token"],
      parameters: .empty
    )

    #expect(response.statusCode == 200)
  }

  @Test("request injects SeSACKey without implicit authorization")
  func requestInjectsDefaultHeaders() async throws {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      #expect(request.value(forHTTPHeaderField: "SeSACKey") == Server.apiKey())
      #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
      return TestURLProtocol.StubResponse(statusCode: 200)
    }

    let response = try await manager.request(TestRouter.search, parameters: .empty)

    #expect(response.statusCode == 200)
  }

  @Test("transport failures map to network transport error")
  func requestMapsTransportFailure() async {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { _ in
      throw URLError(.notConnectedToInternet)
    }

    do {
      _ = try await manager.request(TestRouter.search, parameters: .empty)
      Issue.record("Expected transport error")
    } catch let error as NetworkError {
      #expect(error == .transport)
    } catch {
      Issue.record("Unexpected error: \(error)")
    }
  }

  private func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [TestURLProtocol.self]
    return URLSession(configuration: configuration)
  }
}

private nonisolated func requestBodyData(from request: URLRequest) -> Data? {
  if let body = request.httpBody {
    return body
  }

  guard let stream = request.httpBodyStream else {
    return nil
  }

  stream.open()
  defer { stream.close() }

  var data = Data()
  var buffer = [UInt8](repeating: 0, count: 1_024)

  while stream.hasBytesAvailable {
    let count = stream.read(&buffer, maxLength: buffer.count)
    guard count > 0 else { break }
    data.append(buffer, count: count)
  }

  return data
}

private enum TestRouter: ApiRouter {
  case join
  case search

  var url: String {
    switch self {
    case .join:
      "https://example.com/users/join"
    case .search:
      "https://example.com/users/search"
    }
  }

  var method: HttpMethod {
    switch self {
    case .join:
      .post
    case .search:
      .get
    }
  }

  var contentType: ContentType {
    .json
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
