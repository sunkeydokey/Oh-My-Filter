import Foundation

final class TestURLProtocol: URLProtocol, @unchecked Sendable {
  struct StubResponse: Sendable {
    let statusCode: Int
    let data: Data
    let headers: [String: String]

    init(
      statusCode: Int,
      data: Data = Data(),
      headers: [String: String] = [:]
    ) {
      self.statusCode = statusCode
      self.data = data
      self.headers = headers
    }
  }

  private static let lock = NSLock()
  private static var requestHandler: (@Sendable (URLRequest) throws -> StubResponse)?

  static func setRequestHandler(
    _ handler: @escaping @Sendable (URLRequest) throws -> StubResponse
  ) {
    lock.lock()
    requestHandler = handler
    lock.unlock()
  }

  static func reset() {
    lock.lock()
    requestHandler = nil
    lock.unlock()
  }

  // swiftlint:disable static_over_final_class
  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }
  // swiftlint:enable static_over_final_class

  override func startLoading() {
    Self.lock.lock()
    let handler = Self.requestHandler
    Self.lock.unlock()

    guard let handler else {
      client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
      return
    }

    do {
      let response = try handler(request)
      let url = request.url ?? URL(string: "https://example.com")!
      let httpResponse = HTTPURLResponse(
        url: url,
        statusCode: response.statusCode,
        httpVersion: nil,
        headerFields: response.headers
      )!

      client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: response.data)
      client?.urlProtocolDidFinishLoading(self)
    } catch {
      client?.urlProtocol(self, didFailWithError: error)
    }
  }

  override func stopLoading() {}
}
