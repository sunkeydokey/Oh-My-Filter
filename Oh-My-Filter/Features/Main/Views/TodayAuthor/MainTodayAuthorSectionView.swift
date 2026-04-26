import SwiftUI

struct MainTodayAuthorSectionView: View {
  let state: MainSectionState<MainTodayAuthor>
  let retryAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      MainSectionHeaderView(title: "오늘의 작가 소개")

      if let todayAuthor = state.value {
        MainTodayAuthorView(todayAuthor: todayAuthor)
      } else {
        MainTodayAuthorFallbackView(state: state, retryAction: retryAction)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
