import Observation
import SwiftUI

struct ContentView: View {
  @Bindable var coordinator: AppCoordinator
  @Bindable var pushRoutingStore: PushNotificationRoutingStore

  init(
    coordinator: AppCoordinator,
    pushRoutingStore: PushNotificationRoutingStore
  ) {
    self.coordinator = coordinator
    self.pushRoutingStore = pushRoutingStore
  }

  var body: some View {
    Group {
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
        AuthenticatedRootView(
          pendingRoute: coordinator.pendingAuthenticatedRoute,
          onRouteHandled: coordinator.markAuthenticatedRouteHandled
        ) {
          _ = coordinator.logout()
        }
      }
    }
    .onAppear {
      consumePendingPushRoute()
    }
    .onChange(of: pushRoutingStore.pendingRoute) { _, _ in
      consumePendingPushRoute()
    }
  }

  private func consumePendingPushRoute() {
    guard let route = pushRoutingStore.consumePendingRoute() else { return }
    coordinator.receiveAuthenticatedRoute(route)
  }
}

#Preview {
  ContentView(
    coordinator: AppCoordinator(
      loginService: LiveLoginService(),
      signupService: LiveSignupService()
    ),
    pushRoutingStore: PushNotificationRoutingStore()
  )
}
