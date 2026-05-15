import SwiftUI

struct CommunityView: View {
  @State private var viewModel = CommunityViewModel()
  let mutationStore: CommunityPostMutationStore?
  let navigate: (CommunityRoute) -> Void

  init(
    mutationStore: CommunityPostMutationStore? = nil,
    navigate: @escaping (CommunityRoute) -> Void = { _ in }
  ) {
    self.mutationStore = mutationStore
    self.navigate = navigate
  }

  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 18) {
        CommunityHeaderView {
          Task { await viewModel.send(.createPostTapped) }
        }

        CommunitySearchBarView(
          searchText: viewModel.state.searchText,
          onSearchTextChanged: { text in
            Task { await viewModel.send(.searchTextChanged(text)) }
          },
          onSubmitSearch: {
            Task { await viewModel.send(.submitSearch) }
          },
          onClearSearch: {
            Task { await viewModel.send(.clearSearch) }
          }
        )

        CommunityTabBarView(
          selectedTab: viewModel.state.selectedTab,
          onTabSelected: { tab in
            Task { await viewModel.send(.selectedTabChanged(tab)) }
          }
        )

        CommunityFeedSectionView(
          phase: viewModel.state.phase,
          emptyStateKind: viewModel.state.emptyStateKind,
          visibleFeedItems: viewModel.state.visibleFeedItems,
          isLoadingMorePosts: viewModel.state.isLoadingMorePosts,
          isLoadingMoreVideos: viewModel.state.isLoadingMoreVideos,
          isLoadingMoreLikedPosts: viewModel.state.isLoadingMoreLikedPosts,
          paginationErrorMessage: viewModel.state.paginationErrorMessage,
          onRetry: {
            Task { await viewModel.send(.retry) }
          },
          onPostTapped: { postID in
            Task { await viewModel.send(.postTapped(postID)) }
          },
          onVideoTapped: { video in
            Task { await viewModel.send(.videoTapped(video)) }
          },
          onFeedItemAppeared: { item in
            Task { await viewModel.send(.scroll(.feedItemAppeared(item))) }
          },
          onVideoRailItemAppeared: { video in
            Task { await viewModel.send(.scroll(.videoRailItemAppeared(video))) }
          }
        )
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 18)
    }
    .scrollIndicators(.hidden)
    .refreshable {
      await viewModel.send(.refresh)
    }
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
    .task {
      await viewModel.send(.task)
    }
    .onAppear {
      Task {
        await viewModel.send(.viewAppeared)
      }
    }
    .onDisappear {
      Task {
        await viewModel.send(.disappeared)
      }
    }
    .onChange(of: viewModel.state.route) { _, route in
      guard let route else { return }
      navigate(route)
      Task {
        await viewModel.send(.routeHandled)
      }
    }
    .onChange(of: mutationStore?.pendingMutation) { _, mutation in
      guard let mutation else { return }
      Task {
        await viewModel.send(.postMutationReceived(mutation))
        mutationStore?.markHandled()
      }
    }
  }
}
