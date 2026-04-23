import SwiftUI

struct ContentView: View {
  @State private var viewModel = SignupViewModel(service: LiveSignupService())
  @State private var navigationPath: [SignupNavigationDestination] = []

  var body: some View {
    NavigationStack(path: $navigationPath) {
      SignupView(
        viewModel: viewModel,
        onProfileLater: {
          viewModel.dismissSignupCompletionAlert()
          navigationPath.append(.designSystemCatalog)
        },
        onProfileNow: {}
      )
      .navigationDestination(for: SignupNavigationDestination.self) { destination in
        switch destination {
        case .designSystemCatalog:
          DesignSystemCatalogView()
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
