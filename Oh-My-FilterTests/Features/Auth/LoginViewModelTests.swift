import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct LoginViewModelTests {
  @Test("submit enters loading state while request is in flight")
  func submitShowsLoadingState() async {
    let service = ControlledLoginService()
    let viewModel = LoginViewModel(service: service)
    viewModel.send(.emailChanged("sesac@sesac.com"))
    viewModel.send(.passwordChanged("password123!"))

    let task = viewModel.send(.submitTapped)

    #expect(viewModel.state.isSubmitting)

    await service.setResult(.success(.fixture))
    await task?.value

    #expect(viewModel.state.isSubmitting == false)
  }

  @Test("action-based input updates canSubmit")
  func actionBasedInputUpdatesCanSubmit() {
    let viewModel = LoginViewModel(service: ControlledLoginService())

    #expect(viewModel.state.canSubmit == false)

    viewModel.send(.emailChanged("sesac@sesac.com"))
    viewModel.send(.passwordChanged("password123!"))

    #expect(viewModel.state.canSubmit)
  }

  @Test("successful login normalizes credentials and forwards session")
  func submitNormalizesCredentialsAndForwardsSession() async {
    let service = ControlledLoginService()
    await service.setResult(.success(.fixture))

    var receivedSession: LoginSession?
    let viewModel = LoginViewModel(service: service) { session in
      receivedSession = session
    }
    viewModel.send(.emailChanged(" sesac@sesac.com "))
    viewModel.send(.passwordChanged(" password123! "))

    await viewModel.send(.submitTapped)?.value

    #expect(await service.lastRequest == LoginRequest(email: "sesac@sesac.com", password: "password123!"))
    #expect(receivedSession == .fixture)
    #expect(viewModel.state.submissionMessage == nil)
  }

  @Test("successful Kakao login forwards session")
  func kakaoLoginForwardsSession() async {
    let service = ControlledLoginService()
    let kakaoOAuthProvider = ControlledKakaoOAuthProvider()
    await service.setResult(.success(.fixture))
    await kakaoOAuthProvider.setResult(.success("kakao-access-token"))

    var receivedSession: LoginSession?
    let viewModel = LoginViewModel(
      service: service,
      kakaoOAuthProvider: kakaoOAuthProvider
    ) { session in
      receivedSession = session
    }

    await viewModel.send(.kakaoLoginTapped)?.value

    #expect(await service.lastKakaoRequest == KakaoLoginRequest(oauthToken: "kakao-access-token"))
    #expect(receivedSession == .fixture)
    #expect(viewModel.state.submissionMessage == nil)
    #expect(viewModel.state.isSubmitting == false)
  }

  @Test("successful Apple login forwards id token and session")
  func appleLoginForwardsSession() async {
    let service = ControlledLoginService()
    await service.setResult(.success(.fixture))

    var receivedSession: LoginSession?
    let viewModel = LoginViewModel(service: service) { session in
      receivedSession = session
    }

    viewModel.send(.appleLoginStarted)
    await viewModel.send(.appleLoginCompleted(identityToken: Data("apple-id-token".utf8)))?.value

    #expect(await service.lastAppleRequest == AppleLoginRequest(idToken: "apple-id-token"))
    #expect(receivedSession == .fixture)
    #expect(viewModel.state.submissionMessage == nil)
    #expect(viewModel.state.isSubmitting == false)
  }

  @Test("missing Apple id token shows inline message")
  func missingAppleIDTokenShowsInlineMessage() {
    let viewModel = LoginViewModel(service: ControlledLoginService())

    viewModel.send(.appleLoginStarted)
    viewModel.send(.appleLoginCompleted(identityToken: nil))

    #expect(viewModel.state.submissionMessage == "Apple 로그인 정보를 확인할 수 없어요. 다시 시도해 주세요.")
    #expect(viewModel.state.isSubmitting == false)
  }

  @Test("400 error shows inline validation message")
  func invalidRequestShowsInlineMessage() async {
    let service = ControlledLoginService()
    await service.setResult(.failure(LoginServiceError.invalidRequest("필수값을 채워주세요.")))

    let viewModel = LoginViewModel(service: service)
    viewModel.send(.emailChanged("sesac@sesac.com"))
    viewModel.send(.passwordChanged("password123!"))

    await viewModel.send(.submitTapped)?.value

    #expect(viewModel.state.submissionMessage == "필수값을 채워주세요.")
    #expect(viewModel.state.isSubmitting == false)
  }

  @Test("401 error shows account guidance")
  func unauthorizedShowsAccountGuidance() async {
    let service = ControlledLoginService()
    await service.setResult(.failure(LoginServiceError.unauthorized("계정을 확인해주세요.")))

    let viewModel = LoginViewModel(service: service)
    viewModel.send(.emailChanged("sesac@sesac.com"))
    viewModel.send(.passwordChanged("password123!"))

    await viewModel.send(.submitTapped)?.value

    #expect(viewModel.state.submissionMessage == "계정을 확인해주세요.")
  }

  @Test("transport failure is retryable")
  func transportFailureShowsRetryableMessage() async {
    let service = ControlledLoginService()
    await service.setResult(.failure(LoginServiceError.transport))

    let viewModel = LoginViewModel(service: service)
    viewModel.send(.emailChanged("sesac@sesac.com"))
    viewModel.send(.passwordChanged("password123!"))

    await viewModel.send(.submitTapped)?.value

    #expect(viewModel.state.submissionMessage == "네트워크 상태를 확인한 뒤 다시 시도해 주세요.")
    #expect(viewModel.state.isSubmitting == false)
  }
}

private actor ControlledLoginService: LoginServicing {
  private var result: Result<LoginSession, Error>?
  private var continuation: CheckedContinuation<LoginSession, Error>?
  private(set) var lastRequest: LoginRequest?
  private(set) var lastKakaoRequest: KakaoLoginRequest?
  private(set) var lastAppleRequest: AppleLoginRequest?

  func setResult(_ result: Result<LoginSession, Error>) {
    self.result = result

    if let continuation {
      self.continuation = nil
      continuation.resume(with: result)
    }
  }

  func login(request: LoginRequest) async throws -> LoginSession {
    lastRequest = request
    return try await session()
  }

  func loginWithKakao(request: KakaoLoginRequest) async throws -> LoginSession {
    lastKakaoRequest = request
    return try await session()
  }

  func loginWithApple(request: AppleLoginRequest) async throws -> LoginSession {
    lastAppleRequest = request
    return try await session()
  }

  private func session() async throws -> LoginSession {
    if let result {
      return try result.get()
    }

    return try await withCheckedThrowingContinuation { continuation in
      self.continuation = continuation
    }
  }
}

private actor ControlledKakaoOAuthProvider: KakaoOAuthProviding {
  private var result: Result<String, Error> = .success("kakao-access-token")

  func setResult(_ result: Result<String, Error>) {
    self.result = result
  }

  func accessToken() async throws -> String {
    try result.get()
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
