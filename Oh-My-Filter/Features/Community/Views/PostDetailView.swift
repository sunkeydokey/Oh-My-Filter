import SwiftUI

struct PostDetailView: View {
  @State private var viewModel = PostDetailViewModel()
  let postID: String

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        switch viewModel.phase {
        case .initial, .loading:
          ProgressView()
            .tint(ColorToken.sesacFilterBrightTurquoise.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 80)
        case let .error(message):
          Text(message)
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 80)
        case .empty:
          Text("콘텐츠를 찾을 수 없습니다")
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale60.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 80)
        case .loaded:
          if let post = viewModel.post {
            Text(post.title)
              .font(TypographyToken.pretendardTitle1.font)
              .foregroundStyle(ColorToken.grayScale0.color)

            Text("\(post.creator.nick) · 좋아요 \(post.likeCount.formatted(.number))")
              .font(TypographyToken.pretendardCaption1.font)
              .foregroundStyle(ColorToken.grayScale60.color)

            Text(post.content)
              .font(TypographyToken.pretendardBody2.font)
              .foregroundStyle(ColorToken.grayScale30.color)
              .lineSpacing(4)
          }
        }
      }
      .padding(20)
    }
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
    .navigationTitle("포스트")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.load(postID: postID)
    }
  }
}

@MainActor
@Observable
private final class PostDetailViewModel {
  var post: CommunityPost?
  var phase: CommunityLoadPhase = .initial

  private let useCase: any CommunityFeedUseCase

  init(useCase: any CommunityFeedUseCase) {
    self.useCase = useCase
  }

  convenience init() {
    self.init(useCase: LiveCommunityFeedUseCase())
  }

  func load(postID: String) async {
    guard phase == .initial else { return }
    phase = .loading

    do {
      post = try await useCase.loadPostDetail(postID: postID)
      phase = post == nil ? .empty : .loaded
    } catch {
      phase = .error(message: CommunityServiceError.serverError.errorDescription ?? "잠시 후 다시 시도해 주세요.")
    }
  }
}
