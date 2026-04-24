import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
  var state = LoginState()

  private let service: LoginServicing
  var onLoginSucceeded: @MainActor (LoginSession) -> Void

  init(
    service: LoginServicing,
    onLoginSucceeded: @escaping @MainActor (LoginSession) -> Void = { _ in }
  ) {
    self.service = service
    self.onLoginSucceeded = onLoginSucceeded
  }

  @discardableResult
  func send(_ action: LoginAction) -> Task<Void, Never>? {
    switch action {
    case let .emailChanged(email):
      state.email = email
      state.submissionMessage = nil
      return nil
    case let .passwordChanged(password):
      state.password = password
      state.submissionMessage = nil
      return nil
    case .submitTapped:
      return submit()
    }
  }

  private func submit() -> Task<Void, Never>? {
    state.submissionMessage = nil

    guard state.canSubmit else {
      state.submissionMessage = "필수값을 채워주세요."
      return nil
    }

    state.isSubmitting = true
    let request = state.loginRequest

    return Task {
      do {
        let session = try await service.login(request: request)
        state.isSubmitting = false
        onLoginSucceeded(session)
      } catch let error as LoginServiceError {
        state.submissionMessage = error.errorDescription
        state.isSubmitting = false
      } catch {
        state.submissionMessage = "로그인 중 문제가 발생했어요. 다시 시도해 주세요."
        state.isSubmitting = false
      }
    }
  }
}
