import Foundation

nonisolated struct LiveFilterDetailUseCase: FilterDetailUseCase {
  private let service: any FilterDetailServicing

  init(service: any FilterDetailServicing) {
    self.service = service
  }

  @MainActor
  init() {
    self.init(service: LiveFilterDetailService())
  }

  func loadFilterDetail(filterID: String) async throws -> FilterDetail {
    try await service.loadFilterDetail(filterID: filterID)
  }
}
