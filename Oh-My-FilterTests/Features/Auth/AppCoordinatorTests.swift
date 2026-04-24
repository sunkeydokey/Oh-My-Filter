import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct AppCoordinatorTests {
  @Test("coordinator starts on launching scene")
  func startsOnLaunchingScene() {
    let coordinator = makeCoordinator()

    #expect(coordinator.scene == .launching)
    #expect(coordinator.authPath.isEmpty)
    #expect(coordinator.loginViewModel == nil)
    #expect(coordinator.signupViewModel == nil)
  }

  @Test("startup refresh success switches to authenticated scene")
  func startupRefreshSuccessSwitchesToAuthenticatedScene() async {
    let refresher = MockAuthSessionRefresher()
    await refresher.setResult(.success(.tokens))
    let coordinator = makeCoordinator(authSessionRefresher: refresher)

    await coordinator.start()?.value

    #expect(coordinator.scene == .authenticated)
    #expect(coordinator.authPath.isEmpty)
    #expect(coordinator.loginViewModel == nil)
    #expect(coordinator.signupViewModel == nil)
  }

  @Test("startup refresh failure prepares auth scene")
  func startupRefreshFailurePreparesAuthScene() async {
    let refresher = MockAuthSessionRefresher()
    await refresher.setResult(.failure(AuthSessionRefreshError.missingRefreshToken))
    let coordinator = makeCoordinator(authSessionRefresher: refresher)

    await coordinator.start()?.value

    #expect(coordinator.scene == .auth)
    #expect(coordinator.authPath.isEmpty)
    #expect(coordinator.loginViewModel != nil)
    #expect(coordinator.signupViewModel != nil)
  }

  @Test("show signup adds route once")
  func showSignupAddsRouteOnce() async {
    let coordinator = makeCoordinator()
    await coordinator.start()?.value

    coordinator.showSignup()
    coordinator.showSignup()

    #expect(coordinator.authPath == [.signup])
  }

  @Test("return to login clears signup route")
  func returnToLoginClearsRoutes() async {
    let coordinator = makeCoordinator()
    await coordinator.start()?.value

    coordinator.showSignup()
    coordinator.returnToLogin()

    #expect(coordinator.authPath.isEmpty)
    #expect(coordinator.scene == .auth)
  }

  @Test("successful login clears auth stack and switches scene")
  func successfulLoginSwitchesScene() async throws {
    let loginService = MockLoginService()
    await loginService.setResult(.success(.fixture))

    let coordinator = AppCoordinator(
      loginService: loginService,
      signupService: PassiveSignupService()
    )
    await coordinator.start()?.value
    coordinator.showSignup()
    let loginViewModel = try #require(coordinator.loginViewModel)
    loginViewModel.send(.emailChanged(" sesac@sesac.com "))
    loginViewModel.send(.passwordChanged(" password123! "))

    await loginViewModel.send(.submitTapped)?.value

    #expect(coordinator.scene == .authenticated)
    #expect(coordinator.authPath.isEmpty)
    #expect(coordinator.loginViewModel == nil)
    #expect(coordinator.signupViewModel == nil)
  }

  @Test("successful signup clears auth stack and switches scene")
  func successfulSignupSwitchesScene() async throws {
    let coordinator = makeCoordinator()
    await coordinator.start()?.value
    coordinator.showSignup()
    let signupViewModel = try #require(coordinator.signupViewModel)

    await signupViewModel.send(.emailChanged("sesac@sesac.com"))?.value
    signupViewModel.send(.passwordChanged("password123!"))
    signupViewModel.send(.passwordConfirmationChanged("password123!"))
    signupViewModel.send(.nickChanged("새싹이Abc12"))
    await signupViewModel.send(.submitTapped)?.value

    #expect(coordinator.scene == .authenticated)
    #expect(coordinator.authPath.isEmpty)
    #expect(coordinator.loginViewModel == nil)
    #expect(coordinator.signupViewModel == nil)
  }

  @Test("show profile edit adds route once")
  func showProfileEditAddsRouteOnce() async {
    let coordinator = makeCoordinator()
    await coordinator.start()?.value

    coordinator.showProfileEdit()
    coordinator.showProfileEdit()

    #expect(coordinator.authPath == [.profileEdit])
  }

  @Test("logout deletes tokens and recreates auth view models")
  func logoutDeletesTokensAndRecreatesAuthViewModels() async {
    let refresher = MockAuthSessionRefresher()
    await refresher.setResult(.success(.tokens))
    let tokenStore = MockAuthTokenStore()
    await tokenStore.saveWithoutThrowing(.tokens)
    let coordinator = makeCoordinator(authSessionRefresher: refresher, tokenStore: tokenStore)
    await coordinator.start()?.value

    await coordinator.logout().value

    #expect(coordinator.scene == .auth)
    #expect(coordinator.loginViewModel != nil)
    #expect(coordinator.signupViewModel != nil)
    #expect(await tokenStore.tokensWithoutThrowing() == nil)
  }

  private func makeCoordinator(
    authSessionRefresher: MockAuthSessionRefresher = MockAuthSessionRefresher(),
    tokenStore: MockAuthTokenStore = MockAuthTokenStore()
  ) -> AppCoordinator {
    AppCoordinator(
      loginService: MockLoginService(),
      signupService: PassiveSignupService(),
      authSessionRefresher: authSessionRefresher,
      tokenStore: tokenStore
    )
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

  func join(request: SignupRequest) async throws -> LoginSession {
    .fixture
  }
}

private actor MockAuthSessionRefresher: AuthSessionRefreshing {
  private var result: Result<StoredAuthTokens, Error> = .failure(
    AuthSessionRefreshError.missingRefreshToken
  )

  func setResult(_ result: Result<StoredAuthTokens, Error>) {
    self.result = result
  }

  func refreshSession() async throws -> StoredAuthTokens {
    try result.get()
  }
}

private actor MockAuthTokenStore: AuthTokenStoring {
  private var storedTokens: StoredAuthTokens?

  func save(_ tokens: StoredAuthTokens) async throws {
    storedTokens = tokens
  }

  func tokens() async throws -> StoredAuthTokens? {
    storedTokens
  }

  func delete() async throws {
    storedTokens = nil
  }

  func saveWithoutThrowing(_ tokens: StoredAuthTokens) {
    storedTokens = tokens
  }

  func tokensWithoutThrowing() -> StoredAuthTokens? {
    storedTokens
  }
}

private extension StoredAuthTokens {
  static let tokens = StoredAuthTokens(
    accessToken: "access-token",
    refreshToken: "refresh-token",
    accessTokenExpiresAt: Date(timeIntervalSinceReferenceDate: 1_000),
    refreshTokenExpiresAt: Date(timeIntervalSinceReferenceDate: 2_000)
  )
}

private extension LoginSession {
  static let fixture = LoginSession(
    userID: "66115b1197488f90d3e7e6e5",
    email: "sesac@sesac.com",
    nick: "새싹이Abc12",
    profileImage: "/data/profiles/1712413657554.png"
  )
}
