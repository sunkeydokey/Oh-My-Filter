import Foundation

struct SignupState: Equatable, Sendable {
  var email = ""
  var password = ""
  var passwordConfirmation = ""
  var nick = ""
  var emailCheckState: EmailCheckState = .idle
  var submissionMessage: String?
  var isSubmitting = false
  var isShowingSignupCompletionAlert = false

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

  var isPasswordConfirmationSuccess: Bool {
    passwordConfirmationErrorMessage == nil
      && SignupValidator.normalized(passwordConfirmation).isEmpty == false
  }

  private var requiredFieldsAreFilled: Bool {
    SignupValidator.normalized(email).isEmpty == false
      && SignupValidator.normalized(password).isEmpty == false
      && SignupValidator.normalized(passwordConfirmation).isEmpty == false
      && SignupValidator.normalized(nick).isEmpty == false
  }
}
