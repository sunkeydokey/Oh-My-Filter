import Foundation

nonisolated struct LiveOrderCreateUseCase: OrderCreateUseCase {
  private let service: any OrderServicing

  init(service: any OrderServicing) {
    self.service = service
  }

  @MainActor
  init() {
    self.init(service: LiveOrderService())
  }

  func createOrder(filterID: String, totalPrice: Int) async throws -> CreatedOrder {
    try await service.createOrder(
      request: OrderCreateRequest(filterId: filterID, totalPrice: totalPrice)
    )
  }
}
