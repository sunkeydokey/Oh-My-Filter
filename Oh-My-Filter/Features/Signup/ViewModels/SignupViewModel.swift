import Foundation
import Observation

@MainActor
@Observable
final class SignupViewModel {
  var email = ""
  var password = ""
  var passwordConfirmation = ""
  var nick = ""
  var emailCheckState: EmailCheckState = .idle
  var submissionMessage: String?
  var isSubmitting = false
  var isShowingSignupCompletionAlert = false

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

  var emailErrorMessage: String? {
    switch emailCheckState {
    case let .invalidFormat(message),
      let .invalid(message),
      let .duplicate(message),
      let .failed(message):
      message
    case .idle, .checking, .available:
      nil
    }
  }

  var emailSuccessMessage: String? {
    if case let .available(message) = emailCheckState {
      message
    } else {
      nil
    }
  }

  var passwordErrorMessage: String? {
    SignupValidator.passwordErrorMessage(for: password)
  }

  var passwordConfirmationErrorMessage: String? {
    SignupValidator.passwordConfirmationErrorMessage(
      password: password,
      confirmation: passwordConfirmation
    )
  }

  var nickErrorMessage: String? {
    SignupValidator.nickErrorMessage(for: nick)
  }

  var canSubmit: Bool {
    requiredFieldsAreFilled
      && emailCheckState.isSuccess
      && passwordErrorMessage == nil
      && passwordConfirmationErrorMessage == nil
      && nickErrorMessage == nil
      && isSubmitting == false
  }

  var joinRequest: SignupRequest {
    SignupRequest(
      email: SignupValidator.normalized(email),
      password: SignupValidator.normalized(password),
      nick: SignupValidator.normalized(nick)
    )
  }

  func emailChanged(from oldValue: String, to newValue: String) {
    guard oldValue != newValue else { return }

    submissionMessage = nil
    emailValidationTask?.cancel()

    let normalizedEmail = SignupValidator.normalized(newValue)
    guard prepareEmailValidation(for: normalizedEmail) else { return }

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
  }

  func submit() async {
    submissionMessage = nil
    isShowingSignupCompletionAlert = false

    guard canSubmit else {
      submissionMessage = "입력값을 다시 확인해 주세요."
      return
    }

    isSubmitting = true
    defer { isSubmitting = false }

    do {
      try await service.join(request: joinRequest)
      isShowingSignupCompletionAlert = true
    } catch let error as SignupServiceError {
      submissionMessage = error.errorDescription
    } catch {
      submissionMessage = "회원가입 중 문제가 발생했어요. 다시 시도해 주세요."
    }
  }

  func dismissSignupCompletionAlert() {
    isShowingSignupCompletionAlert = false
  }

  private var requiredFieldsAreFilled: Bool {
    SignupValidator.normalized(email).isEmpty == false
      && SignupValidator.normalized(password).isEmpty == false
      && SignupValidator.normalized(passwordConfirmation).isEmpty == false
      && SignupValidator.normalized(nick).isEmpty == false
  }

  private func prepareEmailValidation(for normalizedEmail: String) -> Bool {
    guard normalizedEmail.isEmpty == false else {
      emailCheckState = .idle
      return false
    }

    guard SignupValidator.isValidEmail(normalizedEmail) else {
      emailCheckState = .invalidFormat("올바른 이메일 형식을 입력해 주세요.")
      return false
    }

    emailCheckState = .checking
    return true
  }

  private func updateEmailCheckState(
    for email: String,
    state: @escaping @MainActor () -> EmailCheckState
  ) async {
    guard Task.isCancelled == false else { return }

    await MainActor.run {
      guard SignupValidator.normalized(self.email) == email else { return }
      self.emailCheckState = state()
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
