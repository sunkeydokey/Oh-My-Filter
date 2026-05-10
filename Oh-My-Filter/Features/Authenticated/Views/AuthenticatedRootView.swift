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
  @State private var pendingChatRoomID: String?
  @State private var profilePath: [ProfileRoute] = []
  let pendingRoute: AppAuthenticatedRoute?
  let onRouteHandled: (AppAuthenticatedRoute) -> Void
  let onLogout: () -> Void

  init(
    pendingRoute: AppAuthenticatedRoute? = nil,
    onRouteHandled: @escaping (AppAuthenticatedRoute) -> Void = { _ in },
    onLogout: @escaping () -> Void = {}
  ) {
    self.pendingRoute = pendingRoute
    self.onRouteHandled = onRouteHandled
    self.onLogout = onLogout
  }

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
              FilterDetailView(filterID: filterID) { route in
                mainPath.append(route)
              }
            case .filterMake:
              MakeFilterView { detail in
                MainNavigationPathReducer.replaceFilterMakeWithDetail(
                  detail.id,
                  in: &mainPath
                )
              }
            case let .filterEdit(draft):
              FilterEditView(draft: draft)
            case let .filterUpdate(draft):
              MakeFilterView(mode: .update(filterID: draft.filterID ?? ""), draft: draft)
            }
          }
        }
        .toolbar(.hidden, for: .navigationBar)
      }

      Tab("피드", systemImage: IconToken.board.symbolName, value: .feed) {
        NavigationStack(path: $feedPath) {
          FeedView { route in
            feedPath.append(route)
          }
          .navigationDestination(for: MainRoute.self) { route in
            switch route {
            case let .filterDetail(filterID):
              FilterDetailView(filterID: filterID) { route in
                feedPath.append(route)
              }
            case .filterMake:
              MakeFilterView { detail in
                MainNavigationPathReducer.replaceFilterMakeWithDetail(
                  detail.id,
                  in: &feedPath
                )
              }
            case let .filterEdit(draft):
              FilterEditView(draft: draft)
            case let .filterUpdate(draft):
              MakeFilterView(mode: .update(filterID: draft.filterID ?? ""), draft: draft)
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
            case .postCreate:
              CommunityPostView(mode: .create) { route in
                communityPath.append(route)
              }
            case let .postDetail(postID):
              CommunityPostView(mode: .detail(postID: postID)) { route in
                communityPath.append(route)
              }
            case let .postEdit(postID):
              CommunityPostView(mode: .edit(postID: postID)) { route in
                communityPath.append(route)
              }
            case let .videoDetail(video):
              VideoPlayerView(video: video)
            }
          }
        }
      }

      Tab("채팅", systemImage: "message.circle.fill", value: .chat) {
        NavigationStack {
          ChatListView(pendingRoomID: $pendingChatRoomID)
        }
      }

      Tab("프로필", systemImage: IconToken.profile.symbolName, value: .profile) {
        NavigationStack(path: $profilePath) {
          MyView(
            navigate: { route in
              profilePath.append(route)
            },
            onLogout: onLogout
          )
          .navigationDestination(for: ProfileRoute.self) { route in
            switch route {
            case .profile:
              ProfileView {
                profilePath.append(.edit)
              }
            case .edit:
              ProfileEditView()
            case .receipts:
              ReceiptView()
            }
          }
        }
      }
    }
    .tint(ColorToken.mainAccent.color)
    .toolbarBackground(ColorToken.brandBlackSprout.color, for: .tabBar)
    .toolbarBackground(.visible, for: .tabBar)
    .toolbarColorScheme(.dark, for: .tabBar)
    .onAppear {
      handlePendingRoute(pendingRoute)
    }
    .onChange(of: pendingRoute) { _, route in
      handlePendingRoute(route)
    }
  }

  private func handlePendingRoute(_ route: AppAuthenticatedRoute?) {
    guard let route else { return }

    switch route {
    case let .chatRoom(roomID):
      selectedTab = .chat
      pendingChatRoomID = roomID
    }

    onRouteHandled(route)
  }
}

nonisolated enum MainNavigationPathReducer {
  static func replaceFilterMakeWithDetail(_ filterID: String, in path: inout [MainRoute]) {
    if path.last == .filterMake {
      path.removeLast()
    }
    path.append(.filterDetail(filterID: filterID))
  }
}
