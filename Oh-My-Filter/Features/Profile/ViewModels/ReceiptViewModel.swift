import Foundation
import Observation

nonisolated enum ReceiptAction: Equatable, Sendable {
  case task
  case retry
}

nonisolated struct ReceiptState: Equatable, Sendable {
  var orders: [OrderHistoryItem] = []
  var isLoading = false
  var message: String?
}

@MainActor
@Observable
final class ReceiptViewModel {
  var state = ReceiptState()

  private let useCase: any OrderHistoryUseCase

  init(useCase: (any OrderHistoryUseCase)? = nil) {
    self.useCase = useCase ?? LiveOrderHistoryUseCase()
  }

  func send(_ action: ReceiptAction) async {
    switch action {
    case .task, .retry:
      await load()
    }
  }

  private func load() async {
    state.isLoading = true
    state.message = nil

    do {
      state.orders = try await useCase.loadOrders()
    } catch is CancellationError {
      return
    } catch {
      if let error = error as? LocalizedError, let description = error.errorDescription {
        state.message = description
      } else {
        state.message = "주문 내역을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요."
      }
    }

    state.isLoading = false
  }
}
