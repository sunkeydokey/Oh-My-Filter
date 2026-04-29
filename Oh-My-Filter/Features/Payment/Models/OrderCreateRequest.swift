import Foundation

nonisolated struct OrderCreateRequest: Encodable, Equatable, Sendable {
  let filterId: String
  let totalPrice: Int

  enum CodingKeys: String, CodingKey {
    case filterId = "filter_id"
    case totalPrice = "total_price"
  }
}
