import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
  var email = ""
  var password = ""
  var submissionMessage: String?
  var isSubmitting = false

  private let service: LoginServicing
  var onLoginSucceeded: @MainActor (LoginSession) -> Void

  init(
    service: LoginServicing,
    onLoginSucceeded: @escaping @MainActor (LoginSession) -> Void = { _ in }
  ) {
    self.service = service
    self.onLoginSucceeded = onLoginSucceeded
  }

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

  func submit() async {
    submissionMessage = nil

    guard canSubmit else {
      submissionMessage = "필수값을 채워주세요."
      return
    }

    isSubmitting = true
    defer { isSubmitting = false }

    do {
      let session = try await service.login(request: loginRequest)
      onLoginSucceeded(session)
    } catch let error as LoginServiceError {
      submissionMessage = error.errorDescription
    } catch {
      submissionMessage = "로그인 중 문제가 발생했어요. 다시 시도해 주세요."
    }
  }
}
