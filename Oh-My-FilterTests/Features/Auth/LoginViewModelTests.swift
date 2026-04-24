import Testing
@testable import Oh_My_Filter

@MainActor
struct LoginViewModelTests {
  @Test("submit enters loading state while request is in flight")
  func submitShowsLoadingState() async {
    let service = ControlledLoginService()
    let viewModel = LoginViewModel(service: service)
    viewModel.email = "sesac@sesac.com"
    viewModel.password = "password123!"

    let task = Task {
      await viewModel.submit()
    }

    try? await Task.sleep(for: .milliseconds(20))
    #expect(viewModel.isSubmitting)

    await service.setResult(.success(.fixture))
    await task.value

    #expect(viewModel.isSubmitting == false)
  }

  @Test("successful login normalizes credentials and forwards session")
  func submitNormalizesCredentialsAndForwardsSession() async {
    let service = ControlledLoginService()
    await service.setResult(.success(.fixture))

    var receivedSession: LoginSession?
    let viewModel = LoginViewModel(service: service) { session in
      receivedSession = session
    }
    viewModel.email = " sesac@sesac.com "
    viewModel.password = " password123! "

    await viewModel.submit()

    #expect(await service.lastRequest == LoginRequest(email: "sesac@sesac.com", password: "password123!"))
    #expect(receivedSession == .fixture)
    #expect(viewModel.submissionMessage == nil)
  }

  @Test("400 error shows inline validation message")
  func invalidRequestShowsInlineMessage() async {
    let service = ControlledLoginService()
    await service.setResult(.failure(LoginServiceError.invalidRequest("필수값을 채워주세요.")))

    let viewModel = LoginViewModel(service: service)
    viewModel.email = "sesac@sesac.com"
    viewModel.password = "password123!"

    await viewModel.submit()

    #expect(viewModel.submissionMessage == "필수값을 채워주세요.")
    #expect(viewModel.isSubmitting == false)
  }

  @Test("401 error shows account guidance")
  func unauthorizedShowsAccountGuidance() async {
    let service = ControlledLoginService()
    await service.setResult(.failure(LoginServiceError.unauthorized("계정을 확인해주세요.")))

    let viewModel = LoginViewModel(service: service)
    viewModel.email = "sesac@sesac.com"
    viewModel.password = "password123!"

    await viewModel.submit()

    #expect(viewModel.submissionMessage == "계정을 확인해주세요.")
  }

  @Test("transport failure is retryable")
  func transportFailureShowsRetryableMessage() async {
    let service = ControlledLoginService()
    await service.setResult(.failure(LoginServiceError.transport))

    let viewModel = LoginViewModel(service: service)
    viewModel.email = "sesac@sesac.com"
    viewModel.password = "password123!"

    await viewModel.submit()

    #expect(viewModel.submissionMessage == "네트워크 상태를 확인한 뒤 다시 시도해 주세요.")
    #expect(viewModel.isSubmitting == false)
  }
}

private actor ControlledLoginService: LoginServicing {
  private var result: Result<LoginSession, Error>?
  private var continuation: CheckedContinuation<LoginSession, Error>?
  private(set) var lastRequest: LoginRequest?

  func setResult(_ result: Result<LoginSession, Error>) {
    self.result = result

    if let continuation {
      self.continuation = nil
      continuation.resume(with: result)
    }
  }

  func login(request: LoginRequest) async throws -> LoginSession {
    lastRequest = request

    if let result {
      return try result.get()
    }

    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
    }
  }
}

private extension LoginSession {
  static let fixture = LoginSession(
    userID: "66115b1197488f90d3e7e6e5",
    email: "sesac@sesac.com",
    nick: "새싹이Abc12",
    profileImage: "/data/profiles/1712413657554.png",
    accessToken: "access-token",
    refreshToken: "refresh-token"
  )
}
