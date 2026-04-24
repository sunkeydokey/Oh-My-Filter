import Foundation
import Observation

@MainActor
@Observable
final class AppCoordinator {
  var scene: AppScene = .auth
  var authPath: [AuthRoute] = []

  var loginViewModel: LoginViewModel
  var signupViewModel: SignupViewModel

  init(
    loginService: LoginServicing,
    signupService: SignupServicing
  ) {
    loginViewModel = LoginViewModel(service: loginService)
    signupViewModel = SignupViewModel(service: signupService)
    loginViewModel.onLoginSucceeded = { [weak self] _ in
      self?.finishAuthentication()
    }
  }

  func showSignup() {
    guard authPath.contains(.signup) == false else { return }
    authPath.append(.signup)
  }

  func returnToLogin() {
    authPath.removeAll()
  }

  func finishAuthentication() {
    authPath.removeAll()
    scene = .authenticated
  }

  func logout() {
    authPath.removeAll()
    scene = .auth
  }
}
