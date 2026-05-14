import Kingfisher
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
        header
        searchBar
        tabBar
        content
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

  private var header: some View {
    HStack {
      Text("Community")
        .font(.custom(TypographyToken.mulgyeolTitle1.fontName, size: 24, relativeTo: .title2))
        .foregroundStyle(ColorToken.grayScale0.color)

      Spacer()

      Button {
        Task {
          await viewModel.send(.createPostTapped)
        }
      } label: {
        Image(systemName: "square.and.pencil")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(ColorToken.grayScale0.color)
          .frame(width: 38, height: 38)
          .background(ColorToken.brandBlackSprout.color, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("게시글 작성")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var searchBar: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(ColorToken.grayScale60.color)

      TextField("제목으로 검색", text: Binding(
        get: { viewModel.state.searchText },
        set: { text in
          Task {
            await viewModel.send(.searchTextChanged(text))
          }
        }
      ))
      .font(TypographyToken.pretendardBody2.font)
      .foregroundStyle(ColorToken.grayScale0.color)
      .submitLabel(.search)
      .onSubmit {
        Task {
          await viewModel.send(.submitSearch)
        }
      }

      if viewModel.state.searchText.isEmpty == false {
        Button {
          Task {
            await viewModel.send(.clearSearch)
          }
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(ColorToken.grayScale60.color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("검색어 지우기")
      }
    }
    .frame(height: 48)
    .padding(.horizontal, 16)
    .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
  }

  private var tabBar: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(CommunityTab.allCases, id: \.self) { tab in
          Button {
            Task {
              await viewModel.send(.selectedTabChanged(tab))
            }
          } label: {
            Text(tab.title)
              .font(TypographyToken.pretendardCaption1.font)
              .foregroundStyle(viewModel.state.selectedTab == tab ? ColorToken.grayScale100.color : ColorToken.grayScale0.color)
              .padding(.horizontal, 16)
              .frame(height: 34)
              .background(tabFill(for: tab), in: Capsule())
              .buttonHitArea(Capsule())
          }
          .buttonStyle(.plain)
        }
      }
    }
    .scrollIndicators(.hidden)
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state.phase {
    case .initial, .loading:
      CommunityLoadingView()
    case let .error(message):
      CommunityErrorView(message: message) {
        Task {
          await viewModel.send(.retry)
        }
      }
    case .empty, .loaded:
      if let emptyStateKind = viewModel.state.emptyStateKind {
        CommunityEmptyView(kind: emptyStateKind)
      } else {
        feedItems
      }
    }
  }

  private var feedItems: some View {
    LazyVStack(alignment: .leading, spacing: 0) {
      ForEach(viewModel.state.visibleFeedItems) { item in
        switch item {
        case let .post(post):
          CommunityPostCell(post: post)
            .contentShape(Rectangle())
            .onTapGesture {
              Task {
                await viewModel.send(.postTapped(post.id))
              }
            }
            .accessibilityAddTraits(.isButton)
            .task {
              await viewModel.send(.scroll(.feedItemAppeared(item)))
            }
        case let .video(video):
          Button {
            Task {
              await viewModel.send(.videoTapped(video))
            }
          } label: {
            CommunityVideoRow(video: video)
          }
          .buttonStyle(.plain)
          .padding(.vertical, 10)
          .task {
            await viewModel.send(.scroll(.feedItemAppeared(item)))
          }
        case let .videoRail(videos):
          CommunityVideoRailView(
            videos: videos,
            onTap: { video in
              Task {
                await viewModel.send(.videoTapped(video))
              }
            },
            onScrollNearEnd: { video in
              Task {
                await viewModel.send(.scroll(.videoRailItemAppeared(video)))
              }
            }
          )
          .padding(.vertical, 18)
        }
      }

      if viewModel.state.isLoadingMorePosts || viewModel.state.isLoadingMoreVideos || viewModel.state.isLoadingMoreLikedPosts {
        ProgressView()
          .tint(ColorToken.mainAccent.color)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 20)
      }

      if let message = viewModel.state.paginationErrorMessage {
        Text(message)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
      }
    }
  }

  private func tabFill(for tab: CommunityTab) -> Color {
    viewModel.state.selectedTab == tab
      ? ColorToken.mainAccent.color
      : ColorToken.brandBlackSprout.color
  }
}

private struct CommunityPostCell: View {
  let post: CommunityPost

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(post.title)
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)

      HStack(spacing: 8) {
        Text(post.creator.nick)
        Text(post.category)
        Text("좋아요 \(post.likeCount.formatted(.number))")
      }
      .font(TypographyToken.pretendardCaption1.font)
      .foregroundStyle(ColorToken.grayScale60.color)
      .lineLimit(1)

      Text(post.summary)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale45.color)
        .lineLimit(2)

      if post.attachments.isEmpty == false {
        CommunityPostMediaSection(attachments: post.attachments)
          .padding(.top, 4)
      }

      Divider()
        .overlay(ColorToken.grayScale90.color)
        .padding(.top, 8)
    }
    .padding(.vertical, 16)
  }
}

private struct CommunityPostMediaSection: View {
  let attachments: [CommunityAttachment]
  @State private var currentIndex = 0

  var body: some View {
    if attachments.isEmpty { return AnyView(EmptyView()) }
    return AnyView(carousel)
  }

  private var carousel: some View {
    TabView(selection: $currentIndex) {
      ForEach(Array(attachments.enumerated()), id: \.offset) { index, attachment in
        Group {
          switch attachment {
          case .image(let url):
            CommunityPostRemoteImage(url: url)
          case .video(let url):
            PostVideoPreviewView(url: url, isActive: index == currentIndex)
          }
        }
        .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: attachments.count > 1 ? .automatic : .never))
    .aspectRatio(1, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.45), lineWidth: 1)
    }
    .overlay(alignment: .bottomTrailing) {
      if attachments.count > 1 {
        Text("\(currentIndex + 1) / \(attachments.count)")
          .font(TypographyToken.pretendardCaption2.font.weight(.semibold))
          .foregroundStyle(ColorToken.grayScale0.color)
          .padding(.horizontal, 8)
          .frame(height: 26)
          .background(ColorToken.brandBlackSprout.color.opacity(0.72), in: Capsule())
          .padding(10)
      }
    }
  }
}

private struct CommunityPostRemoteImage: View {
  let url: URL

  var body: some View {
    KFImage(url)
      .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
      .placeholder {
        CommunityPostImageSkeletonView()
      }
      .resizable()
      .scaledToFill()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(ColorToken.brandBlackSprout.color)
      .clipped()
  }
}

private struct CommunityPostImageSkeletonView: View {
  var body: some View {
    ZStack {
      ColorToken.grayScale90.color.opacity(0.45)

      Image(systemName: "photo")
        .font(.system(size: 30, weight: .regular))
        .foregroundStyle(ColorToken.grayScale60.color)
    }
  }
}

private struct CommunityVideoRailView: View {
  let videos: [CommunityVideo]
  let onTap: (CommunityVideo) -> Void
  let onScrollNearEnd: (CommunityVideo) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("지금 많이 보는 영상")
        .font(TypographyToken.pretendardTitle1.font)
        .foregroundStyle(ColorToken.grayScale0.color)

      ScrollView(.horizontal) {
        LazyHStack(spacing: 12) {
          ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
            Button {
              onTap(video)
            } label: {
              CommunityVideoCard(video: video)
            }
            .buttonStyle(.plain)
            .task {
              guard shouldRequestMoreVideos(index: index, count: videos.count) else { return }
              onScrollNearEnd(video)
            }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }

  private func shouldRequestMoreVideos(index: Int, count: Int) -> Bool {
    if count <= 4 {
      return index == count - 1
    }

    return index >= count - 4
  }
}

private struct CommunityVideoCard: View {
  let video: CommunityVideo

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      CommunityThumbnailView(url: video.thumbnailURL)
        .frame(width: 180, height: 108)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

      Text(video.title)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .lineLimit(2)

      Text("조회 \(video.viewCount.formatted(.number))")
        .font(TypographyToken.pretendardCaption1.font)
        .foregroundStyle(ColorToken.grayScale60.color)
    }
    .frame(width: 180, alignment: .leading)
  }
}

private struct CommunityVideoRow: View {
  let video: CommunityVideo

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      CommunityThumbnailView(url: video.thumbnailURL)
        .frame(width: 132, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

      VStack(alignment: .leading, spacing: 8) {
        Text(video.title)
          .font(TypographyToken.pretendardBody1.font)
          .foregroundStyle(ColorToken.grayScale0.color)
          .lineLimit(2)

        Text(video.description)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .lineLimit(2)

        Text("조회 \(video.viewCount.formatted(.number)) · 좋아요 \(video.likeCount.formatted(.number))")
          .font(TypographyToken.pretendardCaption2.font)
          .foregroundStyle(ColorToken.grayScale60.color)
      }
    }
  }
}

private struct CommunityThumbnailView: View {
  let url: URL?

  var body: some View {
    KFImage(url)
      .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
      .placeholder {
        ZStack {
          ColorToken.brandBlackSprout.color
          Image(systemName: "play.fill")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(ColorToken.grayScale60.color)
        }
      }
      .resizable()
      .scaledToFill()
      .background(ColorToken.brandBlackSprout.color)
  }
}

private struct CommunityLoadingView: View {
  var body: some View {
    VStack(spacing: 14) {
      ForEach(0 ..< 5, id: \.self) { _ in
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(ColorToken.brandBlackSprout.color)
          .frame(height: 86)
      }
    }
    .padding(.top, 8)
  }
}

private struct CommunityErrorView: View {
  let message: String
  let retry: () -> Void

  var body: some View {
    VStack(spacing: 14) {
      Text(message)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale45.color)

      Button(action: retry) {
        Text("다시 시도")
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale100.color)
          .padding(.horizontal, 16)
          .frame(height: 40)
          .background(ColorToken.mainAccent.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
          .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
  }
}

private struct CommunityEmptyView: View {
  let kind: CommunityEmptyStateKind

  var body: some View {
    Text(kind.title)
      .font(TypographyToken.pretendardBody2.font)
      .foregroundStyle(ColorToken.grayScale60.color)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 72)
  }
}
