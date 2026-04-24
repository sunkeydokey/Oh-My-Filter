import Foundation
import Observation

@MainActor
@Observable
final class AppCoordinator {
  var scene: AppScene = .launching
  var authPath: [AuthRoute] = []

  var loginViewModel: LoginViewModel?
  var signupViewModel: SignupViewModel?

  private let loginService: any LoginServicing
  private let signupService: any SignupServicing
  private let authSessionRefresher: any AuthSessionRefreshing
  private let tokenStore: any AuthTokenStoring
  private var hasStarted = false

  init(
    loginService: any LoginServicing,
    signupService: any SignupServicing,
    authSessionRefresher: any AuthSessionRefreshing = LiveAuthSessionRefreshService(),
    tokenStore: any AuthTokenStoring = KeychainAuthTokenStore()
  ) {
    self.loginService = loginService
    self.signupService = signupService
    self.authSessionRefresher = authSessionRefresher
    self.tokenStore = tokenStore
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

  @discardableResult
  func logout() -> Task<Void, Never> {
    authPath.removeAll()
    return Task {
      try? await tokenStore.delete()
      prepareAuthenticationFlow()
    }
  }

  private func prepareAuthenticationFlow() {
    authPath.removeAll()

    let loginViewModel = LoginViewModel(service: loginService)
    let signupViewModel = SignupViewModel(service: signupService)

    loginViewModel.onLoginSucceeded = { [weak self] _ in
      self?.finishAuthentication()
    }
    signupViewModel.onSignupSucceeded = { [weak self] _ in
      self?.finishAuthentication()
    }

    self.loginViewModel = loginViewModel
    self.signupViewModel = signupViewModel
    scene = .auth
  }
}
