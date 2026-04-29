import Foundation

nonisolated struct CreatedOrder: Equatable, Sendable {
  let orderID: String
  let orderCode: String
  let totalPrice: Int
  let createdAt: String
  let updatedAt: String
}
