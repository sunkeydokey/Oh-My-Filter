import SwiftUI

struct MainView: View {
  @StateObject private var viewModel = MainViewModel()
  @State private var didLoad = false

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        VStack(alignment: .leading, spacing: 8) {
          Label("홈", systemImage: IconToken.home.symbolName)
            .font(TypographyToken.pretendardBody1.font)
            .foregroundStyle(ColorToken.grayScale0.color)

          Text("오늘의 필터를 둘러보고, 흐름이 좋은 작품을 이어서 살펴보세요.")
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale60.color)
            .fixedSize(horizontal: false, vertical: true)
        }

        MainTodayFilterSectionView(
          state: viewModel.todayFilterState,
          todayFilter: viewModel.todayFilter,
          retryAction: retryTodayFilter
        )

        MainBannerCarouselSectionView(
          state: viewModel.mainBannersState,
          banners: viewModel.mainBanners,
          retryAction: retryMainBanners
        )

        MainHotTrendSectionView(
          state: viewModel.hotTrendFiltersState,
          hotTrendFilters: viewModel.hotTrendFilters,
          retryAction: retryHotTrendFilters
        )

        MainTodayAuthorSectionView(
          state: viewModel.todayAuthorState,
          todayAuthor: viewModel.todayAuthor,
          retryAction: retryTodayAuthor
        )
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
    }
    .scrollIndicators(.hidden)
    .background {
      LinearGradient(
        colors: [
          ColorToken.brandBlackSprout.color,
          ColorToken.brandDeepSprout.color.opacity(0.92),
          ColorToken.brandBlackSprout.color
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      .ignoresSafeArea()
    }
    .task {
      guard didLoad == false else { return }
      didLoad = true
      await viewModel.load()
    }
  }

  private func retryTodayFilter() {
    Task {
      await viewModel.retryTodayFilter()
    }
  }

  private func retryMainBanners() {
    Task {
      await viewModel.retryMainBanners()
    }
  }

  private func retryHotTrendFilters() {
    Task {
      await viewModel.retryHotTrendFilters()
    }
  }

  private func retryTodayAuthor() {
    Task {
      await viewModel.retryTodayAuthor()
    }
  }
}
