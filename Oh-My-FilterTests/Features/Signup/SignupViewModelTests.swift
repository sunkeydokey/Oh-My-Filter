import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct SignupViewModelTests {
  @Test("email validation debounces and marks availability")
  func emailValidationDebounces() async throws {
    let service = MockSignupService()
    await service.setEmailValidationResult(.available)

    let viewModel = SignupViewModel(
      service: service,
      debounceDuration: .milliseconds(20)
    )

    viewModel.email = "sesac@sesac.com"
    viewModel.emailChanged(from: "", to: viewModel.email)

    #expect(viewModel.emailCheckState == .checking)

    try await Task.sleep(for: .milliseconds(60))

    #expect(viewModel.emailCheckState == .available("사용 가능한 이메일이에요."))
    #expect(await service.validateEmailCallCount == 1)
    #expect(await service.lastValidatedEmail == "sesac@sesac.com")
  }

  @Test("invalid email does not hit remote validation")
  func invalidEmailSkipsRemoteValidation() async {
    let service = MockSignupService()
    let viewModel = SignupViewModel(
      service: service,
      debounceDuration: .milliseconds(20)
    )

    viewModel.email = "wrong-email"
    viewModel.emailChanged(from: "", to: viewModel.email)

    #expect(viewModel.emailCheckState == .invalidFormat("올바른 이메일 형식을 입력해 주세요."))
    #expect(await service.validateEmailCallCount == 0)
  }

  @Test("successful signup opens completion alert")
  func submitShowsCompletionAlert() async {
    let service = MockSignupService()
    await service.setEmailValidationResult(.available)

    let viewModel = SignupViewModel(
      service: service,
      debounceDuration: .milliseconds(10)
    )

    viewModel.email = " sesac@sesac.com "
    viewModel.emailChanged(from: "", to: viewModel.email)
    try? await Task.sleep(for: .milliseconds(40))

    viewModel.password = "sesac1234@"
    viewModel.passwordConfirmation = " sesac1234@ "
    viewModel.nick = "새싹이Abc12"

    await viewModel.submit()

    let request = await service.lastJoinRequest
    #expect(request?.email == "sesac@sesac.com")
    #expect(request?.password == "sesac1234@")
    #expect(request?.nick == "새싹이Abc12")
    #expect(viewModel.submissionMessage == nil)
    #expect(viewModel.isShowingSignupCompletionAlert)
  }

  @Test("failed signup keeps inline error and skips completion alert")
  func submitFailureKeepsInlineError() async {
    let service = MockSignupService()
    await service.setJoinResult(.failure(SignupServiceError.serverError))

    let viewModel = SignupViewModel(service: service)
    viewModel.emailCheckState = .available("사용 가능한 이메일이에요.")
    viewModel.email = "sesac@sesac.com"
    viewModel.password = "sesac1234@"
    viewModel.passwordConfirmation = "sesac1234@"
    viewModel.nick = "새싹이Abc12"

    await viewModel.submit()

    #expect(viewModel.submissionMessage == SignupServiceError.serverError.errorDescription)
    #expect(viewModel.isShowingSignupCompletionAlert == false)
  }

  @Test("completion alert can be dismissed")
  func dismissCompletionAlert() {
    let service = MockSignupService()
    let viewModel = SignupViewModel(service: service)
    viewModel.isShowingSignupCompletionAlert = true

    viewModel.dismissSignupCompletionAlert()

    #expect(viewModel.isShowingSignupCompletionAlert == false)
  }

  @Test("submit stays disabled until email is confirmed")
  func submitRequiresAvailableEmail() {
    let service = MockSignupService()
    let viewModel = SignupViewModel(service: service)

    viewModel.email = "sesac@sesac.com"
    viewModel.password = "sesac1234@"
    viewModel.passwordConfirmation = "sesac1234@"
    viewModel.nick = "새싹이Abc12"

    #expect(viewModel.canSubmit == false)
  }

  @Test("submit stays disabled when password confirmation mismatches")
  func submitRequiresMatchingPasswordConfirmation() {
    let service = MockSignupService()
    let viewModel = SignupViewModel(service: service)

    viewModel.emailCheckState = .available("사용 가능한 이메일이에요.")
    viewModel.email = "sesac@sesac.com"
    viewModel.password = "sesac1234@"
    viewModel.passwordConfirmation = "other1234@"
    viewModel.nick = "새싹이Abc12"

    #expect(viewModel.passwordConfirmationErrorMessage == "비밀번호가 일치하지 않아요.")
    #expect(viewModel.canSubmit == false)
  }
}

actor MockSignupService: SignupServicing {
  private var emailValidationResult: Result<EmailValidationStatus, Error> = .success(.available)
  private var joinResult: Result<Void, Error> = .success(())
  private(set) var validateEmailCallCount = 0
  private(set) var lastValidatedEmail: String?
  private(set) var lastJoinRequest: SignupRequest?

  func setEmailValidationResult(_ status: EmailValidationStatus) {
    emailValidationResult = .success(status)
  }

  func setJoinResult(_ result: Result<Void, Error>) {
    joinResult = result
  }

  func validateEmail(_ email: String) async throws -> EmailValidationStatus {
    validateEmailCallCount += 1
    lastValidatedEmail = email
    return try emailValidationResult.get()
  }

  func join(request: SignupRequest) async throws {
    lastJoinRequest = request
    try joinResult.get()
  }
}
