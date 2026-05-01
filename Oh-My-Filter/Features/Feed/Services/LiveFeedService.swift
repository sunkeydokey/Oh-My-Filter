import Foundation
import OSLog

actor LiveFeedService: FeedServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let decoder: JSONDecoder
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "FeedAPI"
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

  func loadFilters(
    nextCursor: String?,
    limit: Int,
    category: String?,
    sort: FeedSort
  ) async throws -> FeedPage {
    guard limit > 0 else {
      throw FeedServiceError.invalidRequest
    }

    let response: NetworkResponse
    do {
      response = try await networkManager.request(
        FilterApiRouter.list,
        parameters: requestQuery(nextCursor: nextCursor, limit: limit, category: category, sort: sort)
      )
    } catch let error as NetworkError {
      Self.logger.error("❌ [FeedAPI] transport failed error=\(String(describing: error), privacy: .public)")
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [FeedAPI] unexpected failure error=\(String(describing: error), privacy: .public)")
      throw FeedServiceError.transport
    }

    switch response.statusCode {
    case 200 ..< 300:
      do {
        return try decoder.decode(FeedFilterPageDTO.self, from: response.data).toDomain()
      } catch {
        Self.logger.error("❌ [FeedAPI] decode failed error=\(String(describing: error), privacy: .public)")
        throw FeedServiceError.invalidResponse
      }
    case 400:
      throw FeedServiceError.invalidRequest
    default:
      throw FeedServiceError.serverError
    }
  }

  private func requestQuery(
    nextCursor: String?,
    limit: Int,
    category: String?,
    sort: FeedSort
  ) -> RequestQuery {
    var values: [String: String] = [
      "limit": String(limit),
      "order_by": sort.rawValue
    ]

    if let nextCursor, nextCursor.isEmpty == false {
      values["next"] = nextCursor
    }

    if let category, category.isEmpty == false {
      values["category"] = category
    }

    return RequestQuery(values)
  }

  private func mappedNetworkError(_ error: NetworkError) -> FeedServiceError {
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
