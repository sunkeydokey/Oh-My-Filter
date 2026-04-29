import Foundation

nonisolated protocol OrderCreateUseCase: Sendable {
  func createOrder(filterID: String, totalPrice: Int) async throws -> CreatedOrder
}
