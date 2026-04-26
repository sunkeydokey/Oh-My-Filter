import SwiftUI

struct MainView: View {
  @State private var viewModel = MainViewModel()
  @State private var didLoad = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        MainTodayFilterSectionView(
          state: viewModel.state.todayFilter,
          retryAction: retryTodayFilter
        )

        VStack(alignment: .leading, spacing: 32) {
          MainBannerCarouselSectionView(
            state: viewModel.state.mainBanners,
            retryAction: retryMainBanners
          )

          MainHotTrendSectionView(
            state: viewModel.state.hotTrendFilters,
            retryAction: retryHotTrendFilters
          )

          MainTodayAuthorSectionView(
            state: viewModel.state.todayAuthor,
            retryAction: retryTodayAuthor
          )
        }
        .padding(.top, 24)
        .padding(.horizontal, MainViewLayout.contentHorizontalInset)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .ignoresSafeArea(edges: .top)
    .scrollIndicators(.hidden)
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
    .task {
      guard didLoad == false else { return }
      didLoad = true
      await viewModel.send(.task)
    }
  }

  private func retryTodayFilter() {
    Task {
      await viewModel.send(.retryTodayFilter)
    }
  }

  private func retryMainBanners() {
    Task {
      await viewModel.send(.retryMainBanners)
    }
  }

  private func retryHotTrendFilters() {
    Task {
      await viewModel.send(.retryHotTrendFilters)
    }
  }

  private func retryTodayAuthor() {
    Task {
      await viewModel.send(.retryTodayAuthor)
    }
  }
}
