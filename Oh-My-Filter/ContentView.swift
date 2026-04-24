import Observation
import SwiftUI

struct ContentView: View {
  @Bindable var coordinator: AppCoordinator

  init(coordinator: AppCoordinator) {
    self.coordinator = coordinator
  }

  var body: some View {
    switch coordinator.scene {
    case .launching:
      ProgressView()
        .task {
          let task = coordinator.start()
          await task?.value
        }
    case .auth:
      if let loginViewModel = coordinator.loginViewModel,
         let signupViewModel = coordinator.signupViewModel {
        NavigationStack(path: $coordinator.authPath) {
          LoginView(
            viewModel: loginViewModel,
            onSignupTap: coordinator.showSignup
          )
          .navigationDestination(for: AuthRoute.self) { route in
            switch route {
            case .signup:
              SignupView(
                viewModel: signupViewModel,
                onLoginTap: coordinator.returnToLogin,
                onProfileLater: coordinator.finishAuthentication,
                onProfileNow: coordinator.showProfileEdit
              )
            case .profileEdit:
              ProfileEditView()
            }
          }
        }
      } else {
        ProgressView()
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
