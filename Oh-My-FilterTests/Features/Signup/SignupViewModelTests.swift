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

    let task = viewModel.send(.emailChanged("sesac@sesac.com"))

    #expect(viewModel.state.emailCheckState == .checking)

    await task?.value

    #expect(viewModel.state.emailCheckState == .available("사용 가능한 이메일이에요."))
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

    viewModel.send(.emailChanged("wrong-email"))

    #expect(viewModel.state.emailCheckState == .invalidFormat("올바른 이메일 형식을 입력해 주세요."))
    #expect(await service.validateEmailCallCount == 0)
  }

  @Test("successful signup opens completion alert")
  func submitShowsCompletionAlert() async {
    let service = MockSignupService()
    await service.setEmailValidationResult(.available)

    var receivedSession: LoginSession?
    let viewModel = SignupViewModel(
      service: service,
      debounceDuration: .milliseconds(10),
      onSignupSucceeded: { receivedSession = $0 }
    )

    await viewModel.send(.emailChanged(" sesac@sesac.com "))?.value

    viewModel.send(.passwordChanged("sesac1234@"))
    viewModel.send(.passwordConfirmationChanged(" sesac1234@ "))
    viewModel.send(.nickChanged("새싹이Abc12"))

    await viewModel.send(.submitTapped)?.value

    let request = await service.lastJoinRequest
    #expect(request?.email == "sesac@sesac.com")
    #expect(request?.password == "sesac1234@")
    #expect(request?.nick == "새싹이Abc12")
    #expect(viewModel.state.submissionMessage == nil)
    #expect(viewModel.state.isShowingSignupCompletionAlert)
    #expect(receivedSession == .fixture)
  }

  @Test("failed signup keeps inline error and skips completion alert")
  func submitFailureKeepsInlineError() async {
    let service = MockSignupService()
    await service.setJoinResult(.failure(SignupServiceError.serverError))

    let viewModel = SignupViewModel(service: service)
    viewModel.state.emailCheckState = .available("사용 가능한 이메일이에요.")
    viewModel.send(.emailChanged("sesac@sesac.com"))
    viewModel.state.emailCheckState = .available("사용 가능한 이메일이에요.")
    viewModel.send(.passwordChanged("sesac1234@"))
    viewModel.send(.passwordConfirmationChanged("sesac1234@"))
    viewModel.send(.nickChanged("새싹이Abc12"))

    await viewModel.send(.submitTapped)?.value

    #expect(viewModel.state.submissionMessage == SignupServiceError.serverError.errorDescription)
    #expect(viewModel.state.isShowingSignupCompletionAlert == false)
  }

  @Test("completion alert can be dismissed")
  func dismissCompletionAlert() {
    let service = MockSignupService()
    let viewModel = SignupViewModel(service: service)
    viewModel.state.isShowingSignupCompletionAlert = true

    viewModel.send(.completionAlertDismissed)

    #expect(viewModel.state.isShowingSignupCompletionAlert == false)
  }

  @Test("submit stays disabled until email is confirmed")
  func submitRequiresAvailableEmail() {
    let service = MockSignupService()
    let viewModel = SignupViewModel(service: service)

    viewModel.send(.emailChanged("sesac@sesac.com"))
    viewModel.send(.passwordChanged("sesac1234@"))
    viewModel.send(.passwordConfirmationChanged("sesac1234@"))
    viewModel.send(.nickChanged("새싹이Abc12"))

    #expect(viewModel.state.canSubmit == false)
  }

  @Test("submit stays disabled when password confirmation mismatches")
  func submitRequiresMatchingPasswordConfirmation() {
    let service = MockSignupService()
    let viewModel = SignupViewModel(service: service)

    viewModel.send(.emailChanged("sesac@sesac.com"))
    viewModel.state.emailCheckState = .available("사용 가능한 이메일이에요.")
    viewModel.send(.passwordChanged("sesac1234@"))
    viewModel.send(.passwordConfirmationChanged("other1234@"))
    viewModel.send(.nickChanged("새싹이Abc12"))

    #expect(viewModel.state.passwordConfirmationErrorMessage == "비밀번호가 일치하지 않아요.")
    #expect(viewModel.state.canSubmit == false)
  }

  @Test("stale email validation response is ignored")
  func staleEmailValidationResponseIsIgnored() async {
    let service = ControlledSignupService()
    let viewModel = SignupViewModel(
      service: service,
      debounceDuration: .milliseconds(10)
    )

    viewModel.send(.emailChanged("first@sesac.com"))
    try? await Task.sleep(for: .milliseconds(30))

    viewModel.send(.emailChanged("second@sesac.com"))
    try? await Task.sleep(for: .milliseconds(30))

    await service.resumeValidation(
      at: 0,
      with: .success(.available)
    )

    #expect(viewModel.state.emailCheckState == .checking)

    await service.resumeValidation(
      at: 1,
      with: .success(.duplicate)
    )

    try? await Task.sleep(for: .milliseconds(10))

    #expect(viewModel.state.emailCheckState == .duplicate("이미 사용 중인 이메일입니다."))
  }

  @Test("duplicate email keeps submit disabled")
  func duplicateEmailKeepsSubmitDisabled() async {
    let service = MockSignupService()
    await service.setEmailValidationResult(.duplicate)

    let viewModel = SignupViewModel(
      service: service,
      debounceDuration: .milliseconds(10)
    )
    await viewModel.send(.emailChanged("sesac@sesac.com"))?.value

    viewModel.send(.passwordChanged("sesac1234@"))
    viewModel.send(.passwordConfirmationChanged("sesac1234@"))
    viewModel.send(.nickChanged("새싹이Abc12"))

    #expect(viewModel.state.emailCheckState == .duplicate("이미 사용 중인 이메일입니다."))
    #expect(viewModel.state.canSubmit == false)
  }

  @Test("email validation failure shows retry guidance")
  func emailValidationFailureShowsRetryGuidance() async {
    let service = MockSignupService()
    await service.setEmailValidationError(SignupServiceError.serverError)

    let viewModel = SignupViewModel(
      service: service,
      debounceDuration: .milliseconds(10)
    )

    await viewModel.send(.emailChanged("sesac@sesac.com"))?.value

    #expect(viewModel.state.emailCheckState == .failed("이메일 확인 중 문제가 발생했어요. 다시 시도해 주세요."))
    #expect(viewModel.state.canSubmit == false)
  }
}

actor MockSignupService: SignupServicing {
  private var emailValidationResult: Result<EmailValidationStatus, Error> = .success(.available)
  private var joinResult: Result<LoginSession, Error> = .success(.fixture)
  private(set) var validateEmailCallCount = 0
  private(set) var lastValidatedEmail: String?
  private(set) var lastJoinRequest: SignupRequest?

  func setEmailValidationResult(_ status: EmailValidationStatus) {
    emailValidationResult = .success(status)
  }

  func setEmailValidationError(_ error: Error) {
    emailValidationResult = .failure(error)
  }

  func setJoinResult(_ result: Result<LoginSession, Error>) {
    joinResult = result
  }

  func validateEmail(_ email: String) async throws -> EmailValidationStatus {
    validateEmailCallCount += 1
    lastValidatedEmail = email
    return try emailValidationResult.get()
  }

  func join(request: SignupRequest) async throws -> LoginSession {
    lastJoinRequest = request
    return try joinResult.get()
  }
}

actor ControlledSignupService: SignupServicing {
  private var continuations: [CheckedContinuation<EmailValidationStatus, Error>] = []

  func validateEmail(_ email: String) async throws -> EmailValidationStatus {
    try await withCheckedThrowingContinuation { continuation in
      continuations.append(continuation)
    }
  }

  func join(request: SignupRequest) async throws -> LoginSession {
    .fixture
  }

  func resumeValidation(
    at index: Int,
    with result: Result<EmailValidationStatus, Error>
  ) {
    continuations[index].resume(with: result)
  }
}

private extension LoginSession {
  static let fixture = LoginSession(
    userID: "66115b1197488f90d3e7e6e5",
    email: "sesac@sesac.com",
    nick: "새싹이Abc12",
    profileImage: "/data/profiles/1712413657554.png"
  )
}
