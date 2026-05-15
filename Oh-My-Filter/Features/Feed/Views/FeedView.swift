import SwiftUI

struct FeedView: View {
  @State private var viewModel = FeedViewModel()
  let navigate: (MainRoute) -> Void

  init(navigate: @escaping (MainRoute) -> Void = { _ in }) {
    self.navigate = navigate
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 28) {
        CustomRootNavigationHeader(
          title: "FEED",
          trailingIcon: IconToken.add.symbolName,
          trailingAction: { navigate(.filterMake) }
        )
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .accessibilityLabel("필터 만들기")

        FeedContentView(
          sort: viewModel.state.sort,
          isInitialLoading: viewModel.state.isInitialLoading,
          topRankingFilters: viewModel.state.topRankingFilters,
          filters: viewModel.state.filters,
          errorMessage: viewModel.state.errorMessage,
          isLoadingMore: viewModel.state.isLoadingMore,
          paginationErrorMessage: viewModel.state.paginationErrorMessage,
          onSortChanged: { sort in
            Task { await viewModel.send(.sortChanged(sort)) }
          },
          onFilterSelected: { filterID in
            navigate(.filterDetail(filterID: filterID))
          },
          onRetry: {
            Task { await viewModel.send(.retry) }
          },
          onFilterAppeared: { filter in
            Task { await viewModel.send(.loadMoreIfNeeded(filter)) }
          }
        )
      }
      .padding(.bottom, 20)
    }
    .scrollIndicators(.hidden)
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .task {
      await viewModel.send(.task)
    }
  }
}
