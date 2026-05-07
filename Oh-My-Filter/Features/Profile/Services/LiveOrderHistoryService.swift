import Foundation
import OSLog

nonisolated struct LiveOrderHistoryService: OrderHistoryServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "OrderHistoryAPI"
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

  func loadOrders() async throws -> [OrderHistoryItem] {
    let response: NetworkResponse
    do {
      response = try await networkManager.request(OrderApiRouter.list)
    } catch let error as NetworkError {
      throw mappedNetworkError(error)
    } catch {
      throw OrderHistoryServiceError.transport
    }

    guard 200 ..< 300 ~= response.statusCode else {
      throw OrderHistoryServiceError.serverError
    }

    do {
      return try decoder.decode(OrderHistoryResponseDTO.self, from: response.data).data.map { try $0.toDomain() }
    } catch {
      Self.logger.error("Order history decode failed: \(String(describing: error), privacy: .public)")
      throw OrderHistoryServiceError.invalidResponse
    }
  }

  private func mappedNetworkError(_ error: NetworkError) -> OrderHistoryServiceError {
    switch error {
    case .invalidRequest, .invalidResponse:
      .invalidResponse
    case .transport:
      .transport
    }
  }
}

private extension OrderHistoryItemDTO {
  nonisolated func toDomain() throws -> OrderHistoryItem {
    OrderHistoryItem(
      id: orderId,
      orderCode: orderCode,
      filter: filter.toDomain(),
      paidAt: try Date(paidAt, strategy: .iso8601)
    )
  }
}

private extension OrderHistoryFilterDTO {
  nonisolated func toDomain() -> OrderHistoryFilter {
    OrderHistoryFilter(
      id: id ?? title,
      category: category,
      title: title,
      description: description,
      files: files,
      price: price,
      creator: creator.toDomain()
    )
  }
}

private extension OrderHistoryCreatorDTO {
  nonisolated func toDomain() -> OrderHistoryCreator {
    OrderHistoryCreator(
      id: userId,
      nick: nick,
      name: name,
      introduction: introduction,
      profileImage: profileImage,
      hashTags: hashTags
    )
  }
}
