import Foundation
import Observation

@MainActor
@Observable
final class AppCoordinator {
  var scene: AppScene = .launching
  var authPath: [AuthRoute] = []
  var pendingAuthenticatedRoute: AppAuthenticatedRoute?

  var loginViewModel: LoginViewModel?
  var signupViewModel: SignupViewModel?

  private let loginService: any LoginServicing
  private let kakaoOAuthProvider: any KakaoOAuthProviding
  private let signupService: any SignupServicing
  private let authSessionRefresher: any AuthSessionRefreshing
  private let tokenStore: any AuthTokenStoring
  private let userSessionStore: any UserSessionStoring
  private let deviceTokenService: any DeviceTokenServicing
  private let localSessionDataResetter: (any LocalSessionDataResetting)?
  private var hasStarted = false

  init(
    loginService: any LoginServicing,
    kakaoOAuthProvider: any KakaoOAuthProviding = LiveKakaoOAuthProvider(),
    signupService: any SignupServicing,
    authSessionRefresher: any AuthSessionRefreshing,
    tokenStore: any AuthTokenStoring,
    userSessionStore: any UserSessionStoring = AppUserSessionStore(),
    deviceTokenService: (any DeviceTokenServicing)? = nil,
    localSessionDataResetter: (any LocalSessionDataResetting)? = nil
  ) {
    self.loginService = loginService
    self.kakaoOAuthProvider = kakaoOAuthProvider
    self.signupService = signupService
    self.authSessionRefresher = authSessionRefresher
    self.tokenStore = tokenStore
    self.userSessionStore = userSessionStore
    self.deviceTokenService = deviceTokenService ?? LiveDeviceTokenService()
    self.localSessionDataResetter = localSessionDataResetter
  }

  @MainActor
  convenience init(
    loginService: any LoginServicing,
    signupService: any SignupServicing,
    localSessionDataResetter: (any LocalSessionDataResetting)? = nil
  ) {
    self.init(
      loginService: loginService,
      kakaoOAuthProvider: LiveKakaoOAuthProvider(),
      signupService: signupService,
      authSessionRefresher: LiveAuthSessionRefreshService(),
      tokenStore: KeychainAuthTokenStore(),
      userSessionStore: AppUserSessionStore(),
      deviceTokenService: LiveDeviceTokenService(),
      localSessionDataResetter: localSessionDataResetter
    )
  }

  @discardableResult
  func start() -> Task<Void, Never>? {
    guard hasStarted == false else { return nil }
    hasStarted = true

    return Task {
      do {
        _ = try await authSessionRefresher.refreshSession()
        finishAuthentication()
      } catch {
        prepareAuthenticationFlow()
      }
    }
  }

  func showSignup() {
    guard authPath.contains(.signup) == false else { return }
    authPath.append(.signup)
  }

  func returnToLogin() {
    authPath.removeAll()
  }

  func showProfileEdit() {
    guard authPath.contains(.profileEdit) == false else { return }
    authPath.append(.profileEdit)
  }

  func finishAuthentication() {
    authPath.removeAll()
    loginViewModel = nil
    signupViewModel = nil
    scene = .authenticated
  }

  func markAuthenticatedRouteHandled(_ route: AppAuthenticatedRoute) {
    guard pendingAuthenticatedRoute == route else { return }
    pendingAuthenticatedRoute = nil
  }

  func receiveAuthenticatedRoute(_ route: AppAuthenticatedRoute) {
    pendingAuthenticatedRoute = route
  }

  func finishAuthentication(session: LoginSession) {
    resetLocalDataIfNeeded(for: session.userID)
    userSessionStore.saveAuthenticatedUserID(session.userID)
    finishAuthentication()
  }

  @discardableResult
  func logout() -> Task<Void, Never> {
    authPath.removeAll()
    return Task {
      try? await deviceTokenService.updateDeviceToken("")
      try? await tokenStore.delete()
      userSessionStore.clearCurrentUserID()
      prepareAuthenticationFlow()
    }
  }

  private func resetLocalDataIfNeeded(for userID: String) {
    guard
      let previousUserID = userSessionStore.localDataOwnerUserID(),
      previousUserID != userID
    else {
      return
    }

    try? localSessionDataResetter?.resetLocalSessionData()
  }

  private func prepareAuthenticationFlow() {
    authPath.removeAll()

    let loginViewModel = LoginViewModel(
      service: loginService,
      kakaoOAuthProvider: kakaoOAuthProvider
    )
    let signupViewModel = SignupViewModel(service: signupService)

    loginViewModel.onLoginSucceeded = { [weak self] session in
      self?.finishAuthentication(session: session)
    }
    signupViewModel.onSignupSucceeded = { [weak self] session in
      self?.finishAuthentication(session: session)
    }

    self.loginViewModel = loginViewModel
    self.signupViewModel = signupViewModel
    scene = .auth
  }
}
