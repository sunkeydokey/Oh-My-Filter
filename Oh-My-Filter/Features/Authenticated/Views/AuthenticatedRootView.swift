import SwiftUI

private enum AuthenticatedTab: Hashable {
  case main
  case feed
  case community
  case chat
  case profile
}

struct AuthenticatedRootView: View {
  @State private var selectedTab: AuthenticatedTab = .main
  @State private var mainPath: [MainRoute] = []
  @State private var feedPath: [MainRoute] = []
  @State private var communityPath: [CommunityRoute] = []

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
            case .filterMake:
              MakeFilterView()
            case let .filterEdit(draft):
              FilterEditView(draft: draft)
            }
          }
        }
      }

      Tab("피드", systemImage: IconToken.board.symbolName, value: .feed) {
        NavigationStack(path: $feedPath) {
          FeedView { route in
            feedPath.append(route)
          }
          .navigationDestination(for: MainRoute.self) { route in
            switch route {
            case let .filterDetail(filterID):
              FilterDetailView(filterID: filterID)
            case .filterMake:
              MakeFilterView()
            case let .filterEdit(draft):
              FilterEditView(draft: draft)
            }
          }
        }
      }

      Tab("커뮤니티", systemImage: "person.3.fill", value: .community) {
        NavigationStack(path: $communityPath) {
          CommunityView { route in
            communityPath.append(route)
          }
          .navigationDestination(for: CommunityRoute.self) { route in
            switch route {
            case let .postDetail(postID):
              PostDetailView(postID: postID)
            case let .videoDetail(video):
              VideoDetailView(video: video)
            }
          }
        }
      }

      Tab("채팅", systemImage: "message.circle.fill", value: .chat) {
        NavigationStack {
          ChatListView()
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
