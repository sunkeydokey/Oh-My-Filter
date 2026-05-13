import SwiftData
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
  @State private var communityPostMutationStore = CommunityPostMutationStore()
  @State private var pendingChatRoomID: String?
  @State private var profilePath: [ProfileRoute] = []
  let pendingRoute: AppAuthenticatedRoute?
  let onRouteHandled: (AppAuthenticatedRoute) -> Void
  let onLogout: () -> Void
  @Environment(PurchasedFilterStore.self) private var purchasedFilterStore
  @Environment(\.modelContext) private var modelContext
  @Environment(\.videoDownloadManager) private var videoDownloadManager

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
            case let .communityPostCreate(preloadedImages):
              CommunityPostView(
                mode: .create,
                preloadedImages: preloadedImages,
                mutationStore: communityPostMutationStore
              ) { route in
                communityPath.append(route)
              }
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
            case let .communityPostCreate(preloadedImages):
              CommunityPostView(
                mode: .create,
                preloadedImages: preloadedImages,
                mutationStore: communityPostMutationStore
              ) { route in
                communityPath.append(route)
              }
            }
          }
        }
      }

      Tab("커뮤니티", systemImage: "person.3.fill", value: .community) {
        NavigationStack(path: $communityPath) {
          CommunityView(mutationStore: communityPostMutationStore) { route in
            communityPath.append(route)
          }
          .navigationDestination(for: CommunityRoute.self) { route in
            switch route {
            case .postCreate:
              CommunityPostView(mode: .create, mutationStore: communityPostMutationStore) { route in
                communityPath.append(route)
              }
            case let .postDetail(postID):
              CommunityPostView(mode: .detail(postID: postID), mutationStore: communityPostMutationStore) { route in
                communityPath.append(route)
              }
            case let .postEdit(postID):
              CommunityPostView(mode: .edit(postID: postID), mutationStore: communityPostMutationStore) { route in
                communityPath.append(route)
              }
            case let .videoDetail(video):
              if let downloadManager = videoDownloadManager {
                VideoPlayerView(
                  video: video,
                  offlineStore: SwiftDataOfflineVideoStore(context: modelContext),
                  downloadManager: downloadManager
                )
              }
            }
          }
        }
        .task {
          await purchasedFilterStore.load()
          Task {
            await purchasedFilterStore.sync()
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
              ReceiptView { route in
                profilePath.append(route)
              }
            case let .playground(filter):
              PlaygroundView(filter: filter) { route in
                profilePath.append(route)
              }
            case let .communityPostCreate(preloadedImages):
              CommunityPostView(
                mode: .create,
                preloadedImages: preloadedImages,
                mutationStore: communityPostMutationStore
              ) { route in
                communityPath.append(route)
              }
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
    case .profileEdit:
      selectedTab = .profile
      profilePath = [.edit]
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
