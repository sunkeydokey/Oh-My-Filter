import Foundation
import Observation

@MainActor
@Observable
final class SignupViewModel {
  var state = SignupState()

  private let service: SignupServicing
  private let debounceDuration: Duration
  private var emailValidationTask: Task<Void, Never>?

  init(
    service: SignupServicing,
    debounceDuration: Duration = .seconds(2)
  ) {
    self.service = service
    self.debounceDuration = debounceDuration
  }

  @discardableResult
  func send(_ action: SignupAction) -> Task<Void, Never>? {
    switch action {
    case let .emailChanged(email):
      guard state.email != email else { return nil }
      state.email = email
      return validateEmailAfterChange(email)
    case let .passwordChanged(password):
      state.password = password
      state.submissionMessage = nil
      return nil
    case let .passwordConfirmationChanged(passwordConfirmation):
      state.passwordConfirmation = passwordConfirmation
      state.submissionMessage = nil
      return nil
    case let .nickChanged(nick):
      state.nick = nick
      state.submissionMessage = nil
      return nil
    case .submitTapped:
      return submit()
    case .completionAlertDismissed:
      state.isShowingSignupCompletionAlert = false
      return nil
    }
  }

  private func validateEmailAfterChange(_ email: String) -> Task<Void, Never>? {
    state.submissionMessage = nil
    emailValidationTask?.cancel()

    let normalizedEmail = SignupValidator.normalized(email)
    guard prepareEmailValidation(for: normalizedEmail) else { return nil }

    emailValidationTask = Task { [service, debounceDuration, normalizedEmail] in
      do {
        try await Task.sleep(for: debounceDuration)
        let status = try await service.validateEmail(normalizedEmail)
        await updateEmailCheckState(for: normalizedEmail) {
          self.mappedEmailCheckState(status)
        }
      } catch is CancellationError {
        return
      } catch let error as SignupServiceError {
        await updateEmailCheckState(for: normalizedEmail) {
          self.mappedEmailCheckState(error)
        }
      } catch {
        await updateEmailCheckState(for: normalizedEmail) {
          .failed("이메일 확인 중 문제가 발생했어요. 다시 시도해 주세요.")
        }
      }
    }

    return emailValidationTask
  }

  private func submit() -> Task<Void, Never>? {
    state.submissionMessage = nil
    state.isShowingSignupCompletionAlert = false

    guard state.canSubmit else {
      state.submissionMessage = "입력값을 다시 확인해 주세요."
      return nil
    }

    state.isSubmitting = true
    let request = state.joinRequest

    return Task {
      do {
        try await service.join(request: request)
        state.isShowingSignupCompletionAlert = true
        state.isSubmitting = false
      } catch let error as SignupServiceError {
        state.submissionMessage = error.errorDescription
        state.isSubmitting = false
      } catch {
        state.submissionMessage = "회원가입 중 문제가 발생했어요. 다시 시도해 주세요."
        state.isSubmitting = false
      }
    }
  }

  private func prepareEmailValidation(for normalizedEmail: String) -> Bool {
    guard normalizedEmail.isEmpty == false else {
      state.emailCheckState = .idle
      return false
    }

    guard SignupValidator.isValidEmail(normalizedEmail) else {
      state.emailCheckState = .invalidFormat("올바른 이메일 형식을 입력해 주세요.")
      return false
    }

    state.emailCheckState = .checking
    return true
  }

  private func updateEmailCheckState(
    for email: String,
    state: @escaping @MainActor () -> EmailCheckState
  ) async {
    guard Task.isCancelled == false else { return }

    await MainActor.run {
      guard SignupValidator.normalized(self.state.email) == email else { return }
      self.state.emailCheckState = state()
    }
  }

  private func mappedEmailCheckState(_ status: EmailValidationStatus) -> EmailCheckState {
    switch status {
    case .available:
      .available("사용 가능한 이메일이에요.")
    case .invalid:
      .invalid("서버에서 허용하지 않는 이메일 형식이에요.")
    case .duplicate:
      .duplicate("이미 사용 중인 이메일입니다.")
    }
  }

  private func mappedEmailCheckState(_ error: SignupServiceError) -> EmailCheckState {
    switch error {
    case .invalidEmail:
      .invalid("서버에서 허용하지 않는 이메일 형식이에요.")
    case .duplicateEmail:
      .duplicate("이미 사용 중인 이메일입니다.")
    case .invalidRequest, .serverError, .invalidResponse, .transport:
      .failed("이메일 확인 중 문제가 발생했어요. 다시 시도해 주세요.")
    }
  }
}
