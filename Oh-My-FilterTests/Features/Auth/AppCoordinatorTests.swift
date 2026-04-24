import Testing
@testable import Oh_My_Filter

@MainActor
struct AppCoordinatorTests {
  @Test("coordinator starts on login scene")
  func startsOnLoginScene() {
    let coordinator = AppCoordinator(
      loginService: MockLoginService(),
      signupService: PassiveSignupService()
    )

    #expect(coordinator.scene == .auth)
    #expect(coordinator.authPath.isEmpty)
  }

  @Test("show signup adds route once")
  func showSignupAddsRouteOnce() {
    let coordinator = AppCoordinator(
      loginService: MockLoginService(),
      signupService: PassiveSignupService()
    )

    coordinator.showSignup()
    coordinator.showSignup()

    #expect(coordinator.authPath == [.signup])
  }

  @Test("return to login clears signup route")
  func returnToLoginClearsRoutes() {
    let coordinator = AppCoordinator(
      loginService: MockLoginService(),
      signupService: PassiveSignupService()
    )

    coordinator.showSignup()
    coordinator.returnToLogin()

    #expect(coordinator.authPath.isEmpty)
    #expect(coordinator.scene == .auth)
  }

  @Test("successful login clears auth stack and switches scene")
  func successfulLoginSwitchesScene() async {
    let loginService = MockLoginService()
    await loginService.setResult(.success(.fixture))

    let coordinator = AppCoordinator(
      loginService: loginService,
      signupService: PassiveSignupService()
    )
    coordinator.showSignup()
    coordinator.loginViewModel.send(.emailChanged(" sesac@sesac.com "))
    coordinator.loginViewModel.send(.passwordChanged(" password123! "))

    await coordinator.loginViewModel.send(.submitTapped)?.value

    #expect(coordinator.scene == .authenticated)
    #expect(coordinator.authPath.isEmpty)
  }
}

private actor MockLoginService: LoginServicing {
  private var result: Result<LoginSession, Error> = .success(.fixture)

  func setResult(_ result: Result<LoginSession, Error>) {
    self.result = result
  }

  func login(request: LoginRequest) async throws -> LoginSession {
    try result.get()
  }
}

private actor PassiveSignupService: SignupServicing {
  func validateEmail(_ email: String) async throws -> EmailValidationStatus {
    .available
  }

  func join(request: SignupRequest) async throws {}
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
