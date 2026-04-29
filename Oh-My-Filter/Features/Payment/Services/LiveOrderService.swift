import Foundation
import OSLog

nonisolated struct LiveOrderService: OrderServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "OrderAPI"
  )

  init(
    networkManager: any AuthenticatedNetworkManaging,
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.networkManager = networkManager
    let configuredDecoder = decoder
    configuredDecoder.keyDecodingStrategy = .convertFromSnakeCase
    self.decoder = configuredDecoder
  }

  @MainActor
  init(decoder: JSONDecoder = JSONDecoder()) {
    self.init(networkManager: AuthenticatedNetworkManager(), decoder: decoder)
  }

  func createOrder(request: OrderCreateRequest) async throws -> CreatedOrder {
    let router = OrderApiRouter.create
    Self.logger.debug("➡️ [OrderAPI] POST \(router.url, privacy: .public) started")

    let response: NetworkResponse
    do {
      response = try await networkManager.request(router, body: request)
    } catch let error as NetworkError {
      Self.logger.error("❌ [OrderAPI] transport failed \(String(describing: error), privacy: .public)")
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [OrderAPI] unexpected failure \(String(describing: error), privacy: .public)")
      throw OrderServiceError.transport
    }

    switch response.statusCode {
    case 200 ..< 300:
      do {
        return try decoder.decode(OrderCreateResponseDTO.self, from: response.data).toDomain()
      } catch {
        Self.logger.error("❌ [OrderAPI] decode failed \(String(describing: error), privacy: .public)")
        throw OrderServiceError.invalidResponse
      }
    case 400:
      throw OrderServiceError.invalidRequest
    case 404:
      throw OrderServiceError.filterNotFound
    case 409:
      throw OrderServiceError.alreadyPurchased
    default:
      throw OrderServiceError.serverError
    }
  }

  private func mappedNetworkError(_ error: NetworkError) -> OrderServiceError {
    switch error {
    case .invalidRequest:
      .invalidRequest
    case .invalidResponse:
      .invalidResponse
    case .transport:
      .transport
    }
  }
}

private extension OrderCreateResponseDTO {
  nonisolated func toDomain() -> CreatedOrder {
    CreatedOrder(
      orderID: orderId,
      orderCode: orderCode,
      totalPrice: totalPrice,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}
