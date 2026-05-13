import Kingfisher
import OSLog
import SwiftUI

struct MainView: View {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "MainView"
  )

  @State private var viewModel = MainViewModel()
  @State private var didLoad = false
  let navigate: (MainRoute) -> Void

  init(navigate: @escaping (MainRoute) -> Void = { _ in }) {
    self.navigate = navigate
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 0) {
        MainRedesignedTodayFilterSectionView(
          state: viewModel.state.todayFilter,
          retryAction: retryTodayFilter,
          selectionAction: showFilterDetail
        )

        VStack(alignment: .leading, spacing: 14) {
          MainRedesignedBannerSectionView(
            state: viewModel.state.mainBanners,
            retryAction: retryMainBanners
          )

          MainRedesignedHotTrendSectionView(
            state: viewModel.state.hotTrendFilters,
            retryAction: retryHotTrendFilters,
            selectionAction: showFilterDetail
          )

          MainRedesignedTodayAuthorSectionView(
            state: viewModel.state.todayAuthor,
            retryAction: retryTodayAuthor
          )
        }
        .padding(.top, 14)
        .padding(.horizontal, MainViewLayout.contentHorizontalInset)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 12)
      .padding(.bottom, 14)
    }
    .scrollIndicators(.hidden)
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .onTapGesture {
      Self.logger.debug("🔍 [MainView] Tap detected")
    }
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

  private func showFilterDetail(filterID: String) {
    Self.logger.debug("➡️ [MainView] navigate filter detail filterID=\(filterID, privacy: .public)")
    navigate(.filterDetail(filterID: filterID))
  }
}

private struct MainRedesignedTodayFilterSectionView: View {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "MainTodayFilterCTA"
  )

  let state: MainSectionState<MainTodayFilter>
  let retryAction: () -> Void
  let selectionAction: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      if let todayFilter = state.value {
        header(todayFilter)
          .padding(.horizontal, MainViewLayout.contentHorizontalInset)
          .padding(.top, 4)
          .onTapGesture {
            Self.logger.debug("🔍 [TodayFilterSection] Header tapped")
          }
          .zIndex(1)

        VStack {
          MainRedesignedTodayFilterHeroView(todayFilter: todayFilter)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .padding(.horizontal, MainViewLayout.contentHorizontalInset)
        .onTapGesture {
          Self.logger.debug("🔍 [TodayFilterSection] HeroView tapped")
        }
        .zIndex(0)

        MainRedesignedMoodSectionView()
          .padding(.horizontal, MainViewLayout.contentHorizontalInset)
          .onTapGesture {
            Self.logger.debug("🔍 [TodayFilterSection] MoodSection tapped")
          }
          .zIndex(1)
      } else {
        fallbackContent
          .padding(.horizontal, MainViewLayout.contentHorizontalInset)
          .padding(.top, 4)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func header(_ todayFilter: MainTodayFilter) -> some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text("오늘의 필터")
          .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 13, relativeTo: .callout))
          .fontWeight(.semibold)
          .foregroundStyle(ColorToken.mainAccent.color)

        Text(todayFilter.title)
          .font(.custom(TypographyToken.mulgyeolTitle1.fontName, size: 28, relativeTo: .title))
          .foregroundStyle(ColorToken.grayScale15.color)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 0)

      MainTodayFilterCTAButton {
        showTodayFilterDetail(todayFilter)
      }
    }
  }

  private func showTodayFilterDetail(_ todayFilter: MainTodayFilter) {
    Self.logger.debug(
      "➡️ [MainTodayFilterCTA] tapped todayFilterID=\(todayFilter.id, privacy: .public) title=\(todayFilter.title, privacy: .public)"
    )
    selectionAction(todayFilter.id)
  }

  @ViewBuilder
  private var fallbackContent: some View {
    switch state {
    case .idle, .loading(previous: nil):
      MainTodayFilterLoadingHeroView()
    case let .failed(message, previous: nil):
      MainRedesignedRetryCardView(
        title: "오늘의 필터를 불러오지 못했어요.",
        message: message,
        retryAction: retryAction
      )
    case .loaded, .loading(previous: _), .failed(message: _, previous: _):
      EmptyView()
    }
  }
}

private struct MainTodayFilterCTAButton: View {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "MainTodayFilterCTAButton"
  )

  let action: () -> Void

  var body: some View {
    Button(action: {
      Self.logger.debug("✅ [MainTodayFilterCTAButton] Button action triggered!")
      action()
    }) {
      HStack(spacing: 6) {
        Image(systemName: "sparkles")
          .font(.system(size: 16, weight: .bold))
          .accessibilityHidden(true)

        Text("사용")
          .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 13, relativeTo: .caption))
          .fontWeight(.bold)
          .lineLimit(1)
      }
      .foregroundStyle(ColorToken.grayScale100.color)
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(ColorToken.mainAccent.color, in: Capsule())
      .buttonHitArea(Capsule())
    }
    .frame(height: 36)
    .accessibilityLabel("사용")
    .onTapGesture {
      Self.logger.debug("🔍 [MainTodayFilterCTAButton] onTapGesture detected")
    }
  }
}

private struct MainRedesignedTodayFilterHeroView: View {
  let todayFilter: MainTodayFilter

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      remoteImage(url: todayFilter.imageUrl) {
        MainTodayFilterHeroFallbackGradientView()
      }
      .frame(maxWidth: .infinity)
      .frame(height: 180)
      .clipped()

      LinearGradient(
        colors: [
          ColorToken.grayScale100.color.opacity(0),
          ColorToken.grayScale100.color.opacity(0.8)
        ],
        startPoint: .top,
        endPoint: .bottom
      )

      Text(todayFilter.description)
        .font(.custom(TypographyToken.pretendardBody3.fontName, size: 11, relativeTo: .caption))
        .fontWeight(.medium)
        .lineSpacing(4)
        .foregroundStyle(ColorToken.grayScale15.color)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          Color(red: 0.09, green: 0.09, blue: 0.11).opacity(0.8),
          in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }
    .frame(maxWidth: .infinity, maxHeight: 180)
    .background(Color(red: 0.09, green: 0.09, blue: 0.11))
    .clipShape(.rect(cornerRadius: 24, style: .continuous))
  }

  private func remoteImage<Placeholder: View>(
    url: URL?,
    @ViewBuilder placeholder: @escaping () -> Placeholder
  ) -> some View {
    Group {
      if let url {
        KFImage(url)
          .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
          .placeholder(placeholder)
          .resizable()
          .scaledToFill()
      } else {
        placeholder()
      }
    }
  }
}

private struct MainRedesignedMoodSectionView: View {
  private let moods: [Mood] = [
    .init(title: "맑은 빛", systemImage: "sun.max.fill"),
    .init(title: "부드러운", systemImage: "leaf.fill"),
    .init(title: "새로운 시작", systemImage: "sparkles")
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("필터 무드")
        .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 15, relativeTo: .callout))
        .fontWeight(.bold)
        .foregroundStyle(ColorToken.grayScale15.color)

      HStack(spacing: 8) {
        ForEach(moods) { mood in
          VStack(spacing: 4) {
            Image(systemName: mood.systemImage)
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(ColorToken.mainAccent.color)

            Text(mood.title)
              .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 11, relativeTo: .caption))
              .fontWeight(.semibold)
              .foregroundStyle(ColorToken.grayScale15.color)
              .lineLimit(1)
              .minimumScaleFactor(0.85)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 9)
          .background(
            Color(red: 0.09, green: 0.09, blue: 0.11),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
          )
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private struct Mood: Identifiable {
    let title: String
    let systemImage: String
    var id: String { title }
  }
}

private struct MainRedesignedBannerSectionView: View {
  let state: MainSectionState<[MainBanner]>
  let retryAction: () -> Void

  @State private var selectedBanner: MainBanner?
  @State private var attendanceResult: AttendanceSuccess?

  var body: some View {
    Group {
      if let banner = state.value?.first {
        Button {
          guard banner.webViewURL != nil else { return }
          selectedBanner = banner
        } label: {
          ZStack(alignment: .leading) {
            MainBannerCardView(banner: banner)
              .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
              colors: [
                ColorToken.grayScale100.color.opacity(0.72),
                ColorToken.grayScale100.color.opacity(0)
              ],
              startPoint: .leading,
              endPoint: .trailing
            )
          }
          .frame(maxWidth: .infinity)
          .frame(height: 110)
          .clipShape(.rect(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
      } else {
        MainBannerFallbackView(state: state, retryAction: retryAction)
      }
    }
    .fullScreenCover(item: $selectedBanner) { banner in
      if let url = banner.webViewURL {
        BannerWebView(
          url: url,
          onComplete: { count in
            attendanceResult = AttendanceSuccess(count: count)
            selectedBanner = nil
          },
          onDismiss: {
            selectedBanner = nil
          }
        )
        .ignoresSafeArea()
      }
    }
    .overlay {
      if let result = attendanceResult {
        CustomAlertSingleButtonView(
          title: "출석 완료!",
          message: "\(result.count)번째 출석이 완료되었습니다.",
          confirmTitle: "확인"
        ) {
          attendanceResult = nil
        }
      }
    }
  }

  private struct AttendanceSuccess: Identifiable, Equatable {
    let id = UUID()
    let count: Int
  }
}

private struct MainRedesignedHotTrendSectionView: View {
  let state: MainSectionState<[MainHotTrendFilter]>
  let retryAction: () -> Void
  let selectionAction: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("핫 트렌드")
          .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 15, relativeTo: .callout))
          .fontWeight(.bold)
          .foregroundStyle(ColorToken.grayScale15.color)

        Spacer(minLength: 0)

        Text("더보기")
          .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 12, relativeTo: .caption))
          .fontWeight(.semibold)
          .foregroundStyle(ColorToken.mainAccent.color)
      }

      if let hotTrendFilters = state.value, hotTrendFilters.isEmpty == false {
        ScrollView(.horizontal) {
          LazyHStack(spacing: 10) {
            ForEach(Array(hotTrendFilters.enumerated()), id: \.element.id) { index, item in
              MainRedesignedHotTrendCardView(
                rank: index + 1,
                item: item,
                selectionAction: selectionAction
              )
            }
          }
          .padding(.horizontal, 1)
        }
        .frame(height: 240)
        .scrollIndicators(.hidden)
      } else {
        MainHotTrendFallbackView(state: state, retryAction: retryAction)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct MainRedesignedHotTrendCardView: View {
  private static let cardWidth: CGFloat = 165

  let rank: Int
  let item: MainHotTrendFilter
  let selectionAction: (String) -> Void

  var body: some View {
    Button {
      selectionAction(item.id)
    } label: {
      VStack(alignment: .leading, spacing: 8) {
        ZStack(alignment: .topTrailing) {
          remoteImage
            .frame(width: Self.cardWidth - 20)
            .frame(height: 194)
            .clipped()
            .clipShape(.rect(cornerRadius: 14, style: .continuous))

          Text(rank.formatted(.number))
            .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 10, relativeTo: .caption2))
            .fontWeight(.bold)
            .foregroundStyle(ColorToken.grayScale100.color)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(ColorToken.mainAccent.color, in: Capsule())
            .padding(8)
        }

        Text(item.title)
          .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 13, relativeTo: .caption))
          .fontWeight(.bold)
          .foregroundStyle(ColorToken.grayScale15.color)
          .lineLimit(1)
          .minimumScaleFactor(0.85)
          .frame(width: Self.cardWidth - 20, alignment: .leading)
      }
      .padding(10)
      .frame(width: Self.cardWidth, height: 240, alignment: .topLeading)
      .background(
        Color(red: 0.09, green: 0.09, blue: 0.11),
        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
      )
    }
    .buttonStyle(.plain)
    .frame(width: Self.cardWidth, height: 240)
  }

  @ViewBuilder
  private var remoteImage: some View {
    if let imageUrl = item.imageUrl {
      KFImage(imageUrl)
        .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
        .placeholder {
          HotTrendCardFallbackBackgroundView()
        }
        .resizable()
        .scaledToFill()
    } else {
      HotTrendCardFallbackBackgroundView()
    }
  }
}

private struct MainRedesignedTodayAuthorSectionView: View {
  let state: MainSectionState<MainTodayAuthor>
  let retryAction: () -> Void

  var body: some View {
    Group {
      if let todayAuthor = state.value {
        HStack(alignment: .center, spacing: 10) {
          avatar(todayAuthor.profileImageUrl)

          VStack(alignment: .leading, spacing: 3) {
            Text("오늘의 작가")
              .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 11, relativeTo: .caption))
              .fontWeight(.bold)
              .foregroundStyle(ColorToken.mainAccent.color)

            Text(todayAuthor.introduction ?? todayAuthor.nick)
              .font(.custom(TypographyToken.mulgyeolCaption1.fontName, size: 13, relativeTo: .caption))
              .foregroundStyle(ColorToken.grayScale15.color)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)

            Text(todayAuthor.description ?? "\(todayAuthor.nick)의 시선으로 만든 필터를 만나보세요.")
              .font(.custom(TypographyToken.pretendardBody3.fontName, size: 10, relativeTo: .caption2))
              .fontWeight(.medium)
              .lineSpacing(2)
              .foregroundStyle(ColorToken.grayScale60.color)
              .lineLimit(2)
          }

          Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
          Color(red: 0.09, green: 0.09, blue: 0.11),
          in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
      } else {
        MainTodayAuthorFallbackView(state: state, retryAction: retryAction)
      }
    }
  }

  private func avatar(_ url: URL?) -> some View {
    Group {
      if let url {
        KFImage(url)
          .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
          .placeholder {
            MainTodayAuthorFallbackAvatarView()
          }
          .resizable()
          .scaledToFill()
      } else {
        MainTodayAuthorFallbackAvatarView()
      }
    }
    .frame(width: 44, height: 44)
    .clipShape(.circle)
    .overlay(
      Circle()
        .stroke(ColorToken.grayScale90.color, lineWidth: 1)
    )
  }
}

private struct MainRedesignedRetryCardView: View {
  let title: String
  let message: String
  let retryAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 15, relativeTo: .callout))
        .fontWeight(.bold)
        .foregroundStyle(ColorToken.grayScale15.color)

      Text(message)
        .font(.custom(TypographyToken.pretendardBody3.fontName, size: 12, relativeTo: .caption))
        .foregroundStyle(ColorToken.grayScale60.color)

      Button(action: retryAction) {
        Text("다시 시도")
          .font(.custom(TypographyToken.pretendardTitle1.fontName, size: 12, relativeTo: .caption))
          .fontWeight(.bold)
          .foregroundStyle(ColorToken.grayScale100.color)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(ColorToken.mainAccent.color, in: Capsule())
          .buttonHitArea(Capsule())
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      Color(red: 0.09, green: 0.09, blue: 0.11),
      in: RoundedRectangle(cornerRadius: 18, style: .continuous)
    )
  }
}
