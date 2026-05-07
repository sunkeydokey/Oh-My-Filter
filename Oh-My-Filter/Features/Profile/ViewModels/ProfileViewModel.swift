import Foundation
import Observation

nonisolated enum ProfileAction: Equatable, Sendable {
  case task
  case retry
}

nonisolated struct ProfileState: Equatable, Sendable {
  var profile: MyProfile?
  var orderCount = 0
  var isLoading = false
  var message: String?
}

@MainActor
@Observable
final class ProfileViewModel {
  var state = ProfileState()

  private let profileUseCase: any ProfileUseCase
  private let orderUseCase: any OrderHistoryUseCase

  init(
    profileUseCase: (any ProfileUseCase)? = nil,
    orderUseCase: (any OrderHistoryUseCase)? = nil
  ) {
    self.profileUseCase = profileUseCase ?? LiveProfileUseCase()
    self.orderUseCase = orderUseCase ?? LiveOrderHistoryUseCase()
  }

  func send(_ action: ProfileAction) async {
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
      let loadedOrders = try await orders
      state.orderCount = loadedOrders.count
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
    return "프로필을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요."
  }
}
