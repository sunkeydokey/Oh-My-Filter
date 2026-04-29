import Foundation

nonisolated struct OrderCreateResponseDTO: Decodable, Equatable, Sendable {
  let orderId: String
  let orderCode: String
  let totalPrice: Int
  let createdAt: String
  let updatedAt: String

  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let wrappedData = try container.decodeIfPresent(OrderCreateResponseDTO.self, forKey: .data)
    if let wrappedData {
      self = wrappedData
      return
    }

    orderId = try container.decode(String.self, forKey: .orderId)
    orderCode = try container.decode(String.self, forKey: .orderCode)
    totalPrice = try container.decode(Int.self, forKey: .totalPrice)
    createdAt = try container.decode(String.self, forKey: .createdAt)
    updatedAt = try container.decode(String.self, forKey: .updatedAt)
  }

  private enum CodingKeys: String, CodingKey {
    case data
    case orderId
    case orderCode
    case totalPrice
    case createdAt
    case updatedAt
  }
}
