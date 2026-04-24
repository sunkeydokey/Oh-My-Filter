import Observation
import SwiftUI

struct ContentView: View {
  @Bindable var coordinator: AppCoordinator

  init(coordinator: AppCoordinator) {
    self.coordinator = coordinator
  }

  var body: some View {
    switch coordinator.scene {
    case .auth:
      NavigationStack(path: $coordinator.authPath) {
        LoginView(
          viewModel: coordinator.loginViewModel,
          onSignupTap: coordinator.showSignup
        )
        .navigationDestination(for: AuthRoute.self) { route in
          switch route {
          case .signup:
            SignupView(
              viewModel: coordinator.signupViewModel,
              onLoginTap: coordinator.returnToLogin,
              onProfileLater: {
                coordinator.signupViewModel.dismissSignupCompletionAlert()
                coordinator.finishAuthentication()
              },
              onProfileNow: {
                coordinator.signupViewModel.dismissSignupCompletionAlert()
                coordinator.finishAuthentication()
              }
            )
          }
        }
      }
    case .authenticated:
      AuthenticatedRootView()
    }
  }
}

#Preview {
  ContentView(
    coordinator: AppCoordinator(
      loginService: LiveLoginService(),
      signupService: LiveSignupService()
    )
  )
}
