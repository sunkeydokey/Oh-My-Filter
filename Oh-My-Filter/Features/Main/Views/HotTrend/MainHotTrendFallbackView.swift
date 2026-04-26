import SwiftUI

struct MainHotTrendFallbackView: View {
  let state: MainSectionState<[MainHotTrendFilter]>
  let retryAction: () -> Void

  var body: some View {
    switch state {
    case .loading, .idle:
      MainHotTrendLoadingView()
    case let .failed(message, previous: nil):
      MainHotTrendFailedCardView(message: message, retryAction: retryAction)
    case .failed, .loaded:
      MainHotTrendEmptyCardView()
    }
  }
}
