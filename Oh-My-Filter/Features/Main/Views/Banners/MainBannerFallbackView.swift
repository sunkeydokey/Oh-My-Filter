import SwiftUI

struct MainBannerFallbackView: View {
  let state: MainSectionState<[MainBanner]>
  let retryAction: () -> Void

  var body: some View {
    switch state {
    case .loading, .idle:
      MainBannerLoadingView()
    case let .failed(message, previous: nil):
      MainBannerFailedCardView(message: message, retryAction: retryAction)
    case .failed, .loaded:
      MainBannerEmptyCardView()
    }
  }
}
