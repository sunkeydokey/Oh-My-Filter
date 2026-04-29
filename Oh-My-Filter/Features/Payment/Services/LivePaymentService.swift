import Foundation
import OSLog

nonisolated struct LivePaymentService: PaymentServicing {
  private let networkManager: any BaseNetworkManaging
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "PaymentAPI"
  )

  init(networkManager: any BaseNetworkManaging) {
    self.networkManager = networkManager
  }

  @MainActor
  init() {
    self.init(networkManager: BaseNetworkManager())
  }

  func validatePayment(request: PaymentValidationRequest) async throws {
    let router = PaymentApiRouter.validation
    Self.logger.debug("➡️ [PaymentAPI] POST \(router.url, privacy: .public) started")

    let response: NetworkResponse
    do {
      response = try await networkManager.request(router, body: request)
    } catch let error as NetworkError {
      Self.logger.error("❌ [PaymentAPI] transport failed \(String(describing: error), privacy: .public)")
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [PaymentAPI] unexpected failure \(String(describing: error), privacy: .public)")
      throw PaymentServiceError.transport
    }

    guard 200 ..< 300 ~= response.statusCode else {
      Self.logger.error("❌ [PaymentAPI] validation status=\(response.statusCode, privacy: .public)")
      
      if response.statusCode == 400 {
        struct ErrorResponse: Decodable {
          let message: String
        }
        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data) {
          Self.logger.error("❌ [PaymentAPI] 400 error message: \(errorResponse.message, privacy: .public)")
        }
      }
      
      Self.logger.error("❌ [PaymentAPI] server error body=\(Self.responseBodyDescription(response.data)), privacy: .public)")
      throw PaymentServiceError.validationFailed
    }
  }

  private func mappedNetworkError(_ error: NetworkError) -> PaymentServiceError {
    switch error {
    case .invalidRequest, .invalidResponse:
      .validationFailed
    case .transport:
      .transport
    }
  }

  private static func responseBodyDescription(_ data: Data) -> String {
    guard let body = String(data: data, encoding: .utf8), body.isEmpty == false else {
      return "<empty>"
    }

    return body
  }
}
