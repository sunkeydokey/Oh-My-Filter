import SwiftUI

struct MainTodayFilterSectionView: View {
  let state: MainSectionState<MainTodayFilter>
  let retryAction: () -> Void
  let selectionAction: (String) -> Void

  var body: some View {
    Group {
      switch state {
      case .idle, .loading(previous: nil):
        MainTodayFilterLoadingHeroView()
      case let .loading(previous?):
        MainTodayFilterHeroView(todayFilter: previous, selectionAction: selectionAction)
      case let .failed(message, previous: nil):
        MainTodayFilterFailedHeroView(message: message, retryAction: retryAction)
      case let .failed(_, previous?):
        MainTodayFilterHeroView(todayFilter: previous, selectionAction: selectionAction)
      case let .loaded(todayFilter):
        MainTodayFilterHeroView(todayFilter: todayFilter, selectionAction: selectionAction)
      }
    }
  }
}
