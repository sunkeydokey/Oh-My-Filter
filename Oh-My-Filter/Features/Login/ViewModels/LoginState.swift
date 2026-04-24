import Foundation

struct LoginState: Equatable, Sendable {
  var email = ""
  var password = ""
  var submissionMessage: String?
  var isSubmitting = false

  var canSubmit: Bool {
    SignupValidator.normalized(email).isEmpty == false
      && SignupValidator.normalized(password).isEmpty == false
      && isSubmitting == false
  }

  var loginRequest: LoginRequest {
    LoginRequest(
      email: SignupValidator.normalized(email),
      password: SignupValidator.normalized(password)
    )
  }
}
