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

  @Test("stale email validation response is ignored")
  func staleEmailValidationResponseIsIgnored() async {
    let service = ControlledSignupService()
    let viewModel = SignupViewModel(
      service: service,
      debounceDuration: .milliseconds(10)
    )

    viewModel.email = "first@sesac.com"
    viewModel.emailChanged(from: "", to: viewModel.email)
    try? await Task.sleep(for: .milliseconds(30))

    viewModel.email = "second@sesac.com"
    viewModel.emailChanged(from: "first@sesac.com", to: viewModel.email)
    try? await Task.sleep(for: .milliseconds(30))

    await service.resumeValidation(
      at: 0,
      with: .success(.available)
    )

    #expect(viewModel.emailCheckState == .checking)

    await service.resumeValidation(
      at: 1,
      with: .success(.duplicate)
    )

    try? await Task.sleep(for: .milliseconds(10))

    #expect(viewModel.emailCheckState == .duplicate("이미 사용 중인 이메일입니다."))
  }

  @Test("duplicate email keeps submit disabled")
  func duplicateEmailKeepsSubmitDisabled() async {
    let service = MockSignupService()
    await service.setEmailValidationResult(.duplicate)

    let viewModel = SignupViewModel(
      service: service,
      debounceDuration: .milliseconds(10)
    )
    viewModel.email = "sesac@sesac.com"
    viewModel.emailChanged(from: "", to: viewModel.email)
    try? await Task.sleep(for: .milliseconds(40))

    viewModel.password = "sesac1234@"
    viewModel.passwordConfirmation = "sesac1234@"
    viewModel.nick = "새싹이Abc12"

    #expect(viewModel.emailCheckState == .duplicate("이미 사용 중인 이메일입니다."))
    #expect(viewModel.canSubmit == false)
  }

  @Test("email validation failure shows retry guidance")
  func emailValidationFailureShowsRetryGuidance() async {
    let service = MockSignupService()
    await service.setEmailValidationError(SignupServiceError.serverError)

    let viewModel = SignupViewModel(
      service: service,
      debounceDuration: .milliseconds(10)
    )

    viewModel.email = "sesac@sesac.com"
    viewModel.emailChanged(from: "", to: viewModel.email)
    try? await Task.sleep(for: .milliseconds(40))

    #expect(viewModel.emailCheckState == .failed("이메일 확인 중 문제가 발생했어요. 다시 시도해 주세요."))
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

  func setEmailValidationError(_ error: Error) {
    emailValidationResult = .failure(error)
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

actor ControlledSignupService: SignupServicing {
  private var continuations: [CheckedContinuation<EmailValidationStatus, Error>] = []

  func validateEmail(_ email: String) async throws -> EmailValidationStatus {
    try await withCheckedThrowingContinuation { continuation in
      continuations.append(continuation)
    }
  }

  func join(request: SignupRequest) async throws {}

  func resumeValidation(
    at index: Int,
    with result: Result<EmailValidationStatus, Error>
  ) {
    continuations[index].resume(with: result)
  }
}
