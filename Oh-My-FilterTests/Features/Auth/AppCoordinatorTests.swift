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

    let coordinator = makeCoordinator(loginService: loginService)
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

  @Test("successful Kakao login clears auth stack and switches scene")
  func successfulKakaoLoginSwitchesScene() async throws {
    let loginService = MockLoginService()
    await loginService.setResult(.success(.fixture))

    let coordinator = makeCoordinator(loginService: loginService)
    await coordinator.start()?.value
    coordinator.showSignup()
    let loginViewModel = try #require(coordinator.loginViewModel)

    await loginViewModel.send(.kakaoLoginTapped)?.value

    #expect(coordinator.scene == .authenticated)
    #expect(coordinator.authPath.isEmpty)
    #expect(coordinator.loginViewModel == nil)
    #expect(coordinator.signupViewModel == nil)
  }

  @Test("successful Apple login clears auth stack and switches scene")
  func successfulAppleLoginSwitchesScene() async throws {
    let loginService = MockLoginService()
    await loginService.setResult(.success(.fixture))

    let coordinator = makeCoordinator(loginService: loginService)
    await coordinator.start()?.value
    coordinator.showSignup()
    let loginViewModel = try #require(coordinator.loginViewModel)

    loginViewModel.send(.appleLoginStarted)
    await loginViewModel.send(.appleLoginCompleted(identityToken: Data("apple-id-token".utf8)))?.value

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
    let userSessionStore = MockUserSessionStore(currentUserID: "66115b1197488f90d3e7e6e5")
    let deviceTokenService = MockDeviceTokenService()
    await tokenStore.saveWithoutThrowing(.tokens)
    let coordinator = makeCoordinator(
      authSessionRefresher: refresher,
      tokenStore: tokenStore,
      userSessionStore: userSessionStore,
      deviceTokenService: deviceTokenService
    )
    await coordinator.start()?.value

    await coordinator.logout().value

    #expect(coordinator.scene == .auth)
    #expect(coordinator.loginViewModel != nil)
    #expect(coordinator.signupViewModel != nil)
    #expect(await tokenStore.tokensWithoutThrowing() == nil)
    #expect(userSessionStore.currentUserID() == nil)
    #expect(deviceTokenService.updatedTokens == [""])
  }

  @Test("successful login stores user id")
  func successfulLoginStoresUserID() async throws {
    let loginService = MockLoginService()
    let userSessionStore = MockUserSessionStore()
    await loginService.setResult(.success(.fixture))
    let coordinator = makeCoordinator(loginService: loginService, userSessionStore: userSessionStore)
    await coordinator.start()?.value
    let loginViewModel = try #require(coordinator.loginViewModel)

    loginViewModel.send(.emailChanged("sesac@sesac.com"))
    loginViewModel.send(.passwordChanged("password123!"))
    await loginViewModel.send(.submitTapped)?.value

    #expect(userSessionStore.currentUserID() == LoginSession.fixture.userID)
    #expect(userSessionStore.localDataOwnerUserID() == LoginSession.fixture.userID)
  }

  @Test("different user login resets local data")
  func differentUserLoginResetsLocalData() async throws {
    let loginService = MockLoginService()
    let userSessionStore = MockUserSessionStore(localDataOwnerUserID: "old-user")
    let resetter = MockLocalSessionDataResetter()
    await loginService.setResult(.success(.fixture))
    let coordinator = makeCoordinator(
      loginService: loginService,
      userSessionStore: userSessionStore,
      localSessionDataResetter: resetter
    )
    await coordinator.start()?.value
    let loginViewModel = try #require(coordinator.loginViewModel)

    loginViewModel.send(.emailChanged("sesac@sesac.com"))
    loginViewModel.send(.passwordChanged("password123!"))
    await loginViewModel.send(.submitTapped)?.value

    #expect(resetter.resetCount == 1)
  }

  @Test("coordinator consumes pending push route")
  func receivesPendingPushRoute() {
    let coordinator = makeCoordinator()
    coordinator.receiveAuthenticatedRoute(.chatRoom(roomID: "room-1"))

    #expect(coordinator.pendingAuthenticatedRoute == .chatRoom(roomID: "room-1"))
  }

  @Test("mark authenticated route handled clears matching route")
  func markAuthenticatedRouteHandledClearsMatchingRoute() {
    let coordinator = makeCoordinator()
    coordinator.receiveAuthenticatedRoute(.chatRoom(roomID: "room-1"))

    coordinator.markAuthenticatedRouteHandled(.chatRoom(roomID: "room-1"))

    #expect(coordinator.pendingAuthenticatedRoute == nil)
  }

  private func makeCoordinator(
    loginService: MockLoginService = MockLoginService(),
    authSessionRefresher: MockAuthSessionRefresher = MockAuthSessionRefresher(),
    tokenStore: MockAuthTokenStore = MockAuthTokenStore(),
    kakaoOAuthProvider: MockKakaoOAuthProvider = MockKakaoOAuthProvider(),
    userSessionStore: MockUserSessionStore = MockUserSessionStore(),
    deviceTokenService: MockDeviceTokenService = MockDeviceTokenService(),
    localSessionDataResetter: (any LocalSessionDataResetting)? = nil
  ) -> AppCoordinator {
    AppCoordinator(
      loginService: loginService,
      kakaoOAuthProvider: kakaoOAuthProvider,
      signupService: PassiveSignupService(),
      authSessionRefresher: authSessionRefresher,
      tokenStore: tokenStore,
      userSessionStore: userSessionStore,
      deviceTokenService: deviceTokenService,
      localSessionDataResetter: localSessionDataResetter
    )
  }
}

private actor MockKakaoOAuthProvider: KakaoOAuthProviding {
  private var result: Result<String, Error> = .success("kakao-access-token")

  func setResult(_ result: Result<String, Error>) {
    self.result = result
  }

  func accessToken() async throws -> String {
    try result.get()
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

  func loginWithKakao(request: KakaoLoginRequest) async throws -> LoginSession {
    try result.get()
  }

  func loginWithApple(request: AppleLoginRequest) async throws -> LoginSession {
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

private final class MockUserSessionStore: UserSessionStoring, @unchecked Sendable {
  private var current: String?
  private var owner: String?

  init(
    currentUserID: String? = nil,
    localDataOwnerUserID: String? = nil
  ) {
    current = currentUserID
    owner = localDataOwnerUserID
  }

  func currentUserID() -> String? {
    current
  }

  func localDataOwnerUserID() -> String? {
    owner
  }

  func saveAuthenticatedUserID(_ userID: String) {
    current = userID
    owner = userID
  }

  func clearCurrentUserID() {
    current = nil
  }
}

private final class MockDeviceTokenService: DeviceTokenServicing, @unchecked Sendable {
  private(set) var updatedTokens: [String] = []

  func updateDeviceToken(_ token: String) async throws {
    updatedTokens.append(token)
  }
}

@MainActor
private final class MockLocalSessionDataResetter: LocalSessionDataResetting {
  private(set) var resetCount = 0

  func resetLocalSessionData() throws {
    resetCount += 1
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
