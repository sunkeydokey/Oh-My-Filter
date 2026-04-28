import SwiftUI

private enum AuthenticatedTab: Hashable {
  case main
  case feed
  case makeFilter
  case search
  case profile
}

struct AuthenticatedRootView: View {
  @State private var selectedTab: AuthenticatedTab = .main
  @State private var mainPath: [MainRoute] = []

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("홈", systemImage: IconToken.home.symbolName, value: .main) {
        NavigationStack(path: $mainPath) {
          MainView { route in
            mainPath.append(route)
          }
          .navigationDestination(for: MainRoute.self) { route in
            switch route {
            case let .filterDetail(filterID):
              FilterDetailView(filterID: filterID)
            }
          }
        }
      }

      Tab("피드", systemImage: IconToken.board.symbolName, value: .feed) {
        NavigationStack {
          FeedView()
        }
      }

      Tab("만들기", systemImage: IconToken.magic.symbolName, value: .makeFilter) {
        NavigationStack {
          MakeFilterView()
        }
      }

      Tab("검색", systemImage: IconToken.search.symbolName, value: .search) {
        NavigationStack {
          SearchView()
        }
      }

      Tab("프로필", systemImage: IconToken.profile.symbolName, value: .profile) {
        NavigationStack {
          ProfileView()
        }
      }
    }
    .tint(ColorToken.sesacFilterBrightTurquoise.color)
    .toolbarBackground(ColorToken.brandBlackSprout.color, for: .tabBar)
    .toolbarBackground(.visible, for: .tabBar)
    .toolbarColorScheme(.dark, for: .tabBar)
  }
}

struct TabScreenView: View {
  let title: String
  let subtitle: String
  let symbolName: String

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Label(title, systemImage: symbolName)
            .font(TypographyToken.pretendardBody1.font)
            .foregroundStyle(ColorToken.grayScale0.color)

          Text(subtitle)
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .fixedSize(horizontal: false, vertical: true)
        }

        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .fill(ColorToken.brandDeepSprout.color)
          .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
              Text(title)
                .font(TypographyToken.pretendardBody1.font)
                .foregroundStyle(ColorToken.grayScale0.color)

              Text("탭 구조를 먼저 연결해 둔 임시 화면입니다.")
                .font(TypographyToken.pretendardBody3.font)
                .foregroundStyle(ColorToken.grayScale45.color)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
          }
          .frame(maxWidth: .infinity)
          .frame(minHeight: 180)
          .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
              .stroke(ColorToken.grayScale90.color, lineWidth: 1)
          )
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(20)
    }
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}
