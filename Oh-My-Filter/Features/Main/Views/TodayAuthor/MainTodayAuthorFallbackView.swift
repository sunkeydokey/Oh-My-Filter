import SwiftUI

struct MainTodayAuthorFallbackView: View {
  let state: MainSectionState<MainTodayAuthor>
  let retryAction: () -> Void

  var body: some View {
    switch state {
    case .loading, .idle:
      MainTodayAuthorLoadingCardView()
    case let .failed(message, previous: nil):
      MainTodayAuthorFailedCardView(message: message, retryAction: retryAction)
    case .failed, .loaded:
      EmptyView()
    }
  }
}
