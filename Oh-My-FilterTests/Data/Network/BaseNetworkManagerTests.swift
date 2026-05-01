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

  @Test("multipart request sends body without JSON encoding")
  func multipartRequestBuildsExpectedBody() async throws {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
      #expect(contentType.starts(with: "multipart/form-data; boundary="))
      #expect(request.value(forHTTPHeaderField: "Accept") == ContentType.json.rawValue)
      #expect(request.value(forHTTPHeaderField: "SeSACKey") == Server.apiKey())

      let body = try #require(requestBodyData(from: request))
      let bodyString = try #require(String(data: body, encoding: .utf8))
      #expect(bodyString.contains("Content-Disposition: form-data; name=\"files\"; filename=\"chat.jpg\""))
      #expect(bodyString.contains("Content-Type: image/jpeg"))
      #expect(bodyString.contains("jpeg-data"))
      #expect(bodyString.contains("--Boundary-"))
      #expect(bodyString.hasSuffix("--\r\n"))

      return TestURLProtocol.StubResponse(statusCode: 200)
    }

    let response = try await manager.request(
      TestRouter.upload,
      multipartFiles: [
        MultipartFilePart(
          fieldName: "files",
          fileName: "chat.jpg",
          mimeType: "image/jpeg",
          data: Data("jpeg-data".utf8)
        ),
      ]
    )

    #expect(response.statusCode == 200)
  }

  @Test("multipart form data builder includes field and delimiter")
  func multipartFormDataBuilder() throws {
    let formData = MultipartFormDataBuilder.build(
      files: [
        MultipartFilePart(
          fieldName: "files",
          fileName: "profile.jpg",
          mimeType: "image/jpeg",
          data: Data("image".utf8)
        ),
      ],
      boundary: "TestBoundary"
    )

    #expect(formData.contentType == "multipart/form-data; boundary=TestBoundary")
    let bodyString = try #require(String(data: formData.body, encoding: .utf8))
    #expect(bodyString.contains("--TestBoundary\r\n"))
    #expect(bodyString.contains("name=\"files\"; filename=\"profile.jpg\""))
    #expect(bodyString.contains("Content-Type: image/jpeg"))
    #expect(bodyString.contains("\r\n\r\nimage\r\n"))
    #expect(bodyString.hasSuffix("--TestBoundary--\r\n"))
  }

  @Test("request injects SeSACKey without implicit authorization")
  func requestInjectsDefaultHeaders() async throws {
    let session = makeSession()
    let manager = BaseNetworkManager(session: session)
    defer { TestURLProtocol.reset() }

    TestURLProtocol.setRequestHandler { request in
      #expect(request.value(forHTTPHeaderField: "SeSACKey") == Server.apiKey())
      #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
      #expect(request.cachePolicy == .reloadIgnoringLocalCacheData)
      #expect(request.value(forHTTPHeaderField: "If-None-Match") == nil)
      #expect(request.value(forHTTPHeaderField: "If-Modified-Since") == nil)
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
  case upload

  var url: String {
    switch self {
    case .join:
      "https://example.com/users/join"
    case .search:
      "https://example.com/users/search"
    case .upload:
      "https://example.com/files"
    }
  }

  var method: HttpMethod {
    switch self {
    case .join, .upload:
      .post
    case .search:
      .get
    }
  }

  var contentType: ContentType {
    switch self {
    case .upload:
      .multipart
    case .join, .search:
      .json
    }
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
