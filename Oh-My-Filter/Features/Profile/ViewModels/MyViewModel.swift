import Foundation
import Observation

nonisolated enum MyAction: Equatable, Sendable {
  case task
  case retry
}

nonisolated struct MyState: Equatable, Sendable {
  var profile: MyProfile?
  var orders: [OrderHistoryItem] = []
  var isLoading = false
  var message: String?
}

@MainActor
@Observable
final class MyViewModel {
  var state = MyState()

  private let profileUseCase: any ProfileUseCase
  private let orderUseCase: any OrderHistoryUseCase

  init(
    profileUseCase: (any ProfileUseCase)? = nil,
    orderUseCase: (any OrderHistoryUseCase)? = nil
  ) {
    self.profileUseCase = profileUseCase ?? LiveProfileUseCase()
    self.orderUseCase = orderUseCase ?? LiveOrderHistoryUseCase()
  }

  func send(_ action: MyAction) async {
    switch action {
    case .task, .retry:
      await load()
    }
  }

  private func load() async {
    state.isLoading = true
    state.message = nil

    do {
      async let profile = profileUseCase.loadMyProfile()
      async let orders = orderUseCase.loadOrders()
      state.profile = try await profile
      state.orders = try await orders
    } catch is CancellationError {
      return
    } catch {
      state.message = fallbackMessage(for: error)
    }

    state.isLoading = false
  }

  private func fallbackMessage(for error: Error) -> String {
    if let error = error as? LocalizedError, let description = error.errorDescription {
      return description
    }
    return "정보를 불러올 수 없습니다. 잠시 후 다시 시도해 주세요."
  }
}
