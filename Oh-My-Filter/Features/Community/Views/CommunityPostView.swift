import Kingfisher
import PhotosUI
import SwiftUI
import UIKit

struct CommunityPostView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: CommunityPostViewModel
  @FocusState private var focusedField: CommunityPostField?
  let navigate: (CommunityRoute) -> Void

  init(
    mode: CommunityPostMode,
    preloadedImages: [PhotoPickerUploadSelection] = [],
    navigate: @escaping (CommunityRoute) -> Void = { _ in }
  ) {
    self._viewModel = State(initialValue: CommunityPostViewModel(mode: mode, preloadedImages: preloadedImages))
    self.navigate = navigate
  }

  var body: some View {
    Group {
      switch viewModel.state.phase {
      case .initial, .loading:
        CommunityPostLoadingView(title: viewModel.state.navigationTitle)
      case let .error(message):
        CommunityPostErrorView(title: viewModel.state.navigationTitle, message: message) {
          Task {
            await viewModel.send(.retry)
          }
        }
      case .empty:
        CommunityPostErrorView(title: viewModel.state.navigationTitle, message: "콘텐츠를 찾을 수 없습니다") {
          Task {
            await viewModel.send(.retry)
          }
        }
      case .loaded:
        loadedContent
      }
    }
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .task {
      await viewModel.send(.task)
    }
    .onChange(of: viewModel.state.route) { _, route in
      guard let route else { return }
      navigate(route)
      Task {
        await viewModel.send(.routeHandled)
      }
    }
    .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
      guard shouldDismiss else { return }
      dismiss()
      Task {
        await viewModel.send(.dismissHandled)
      }
    }
    .confirmationDialog(
      "수정 내용 저장 전",
      isPresented: Binding(
        get: { viewModel.state.showsDiscardConfirmation },
        set: { _ in }
      ),
      titleVisibility: .visible
    ) {
      Button("취소", role: .destructive) {
        Task {
          await viewModel.send(.discardChangesConfirmed)
        }
      }
      Button("계속 수정", role: .cancel) {}
    }
    .confirmationDialog(
      "게시글을 삭제할까요?",
      isPresented: Binding(
        get: { viewModel.state.showsDeleteConfirmation },
        set: { _ in }
      ),
      titleVisibility: .visible
    ) {
      Button("삭제", role: .destructive) {
        Task {
          await viewModel.send(.deleteConfirmed)
        }
      }
      Button("취소", role: .cancel) {}
    }
    .alert(
      "오류",
      isPresented: Binding(
        get: { viewModel.state.errorMessage != nil },
        set: { isPresented in
          if isPresented == false {
            viewModel.state.errorMessage = nil
          }
        }
      )
    ) {
      Button("확인", role: .cancel) {}
    } message: {
      Text(viewModel.state.errorMessage ?? "")
    }
  }

  private var loadedContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        navigationBar
        categorySection
        titleSection
        authorSummary
        bodySection
        imageSection
        metadataSection

        if viewModel.state.isDetail {
          actionBar
          commentSection
        }
      }
      .padding(.horizontal, 20)
      .padding(.bottom, viewModel.state.isDetail ? 24 : 96)
    }
    .scrollIndicators(.hidden)
    .scrollDismissesKeyboard(.interactively)
    .onTapGesture {
      focusedField = nil
    }
    .safeAreaInset(edge: .bottom) {
      if viewModel.state.isDetail == false {
        stickyPrimaryAction
      }
    }
  }

  private var navigationBar: some View {
    HStack(spacing: 12) {
      Button {
        Task {
          await viewModel.send(.cancelTapped)
        }
      } label: {
        if viewModel.state.isDetail {
          Image(systemName: "chevron.left")
            .font(.system(size: 20, weight: .semibold))
            .frame(width: 44, height: 44)
        } else {
          Text("취소")
            .font(TypographyToken.pretendardBody2.font.weight(.bold))
            .frame(height: 44)
        }
      }
      .foregroundStyle(ColorToken.grayScale30.color)
      .buttonStyle(.plain)

      Spacer()

      Text(viewModel.state.navigationTitle)
        .font(.custom(TypographyToken.mulgyeolTitle1.fontName, size: 20, relativeTo: .headline))
        .foregroundStyle(ColorToken.grayScale30.color)

      Spacer()

      if viewModel.state.isDetail {
        Menu {
          if viewModel.state.isOwner {
            Button("수정") {
              Task {
                await viewModel.send(.editTapped)
              }
            }
            Button("삭제", role: .destructive) {
              Task {
                await viewModel.send(.deleteTapped)
              }
            }
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 20, weight: .semibold))
            .frame(width: 44, height: 44)
            .foregroundStyle(ColorToken.grayScale45.color)
        }
        .disabled(viewModel.state.isOwner == false)
      } else {
        Button(viewModel.state.primaryActionTitle) {
          Task {
            await viewModel.send(.submit)
          }
        }
        .font(TypographyToken.pretendardBody2.font.weight(.bold))
        .foregroundStyle(viewModel.state.canSubmit ? ColorToken.mainAccent.color : ColorToken.grayScale60.color)
        .buttonStyle(.plain)
        .disabled(viewModel.state.canSubmit == false)
      }
    }
    .frame(height: 44)
  }

  @ViewBuilder
  private var categorySection: some View {
    if viewModel.state.isDetail {
      Text(viewModel.state.post?.category ?? viewModel.state.draft.category)
        .font(TypographyToken.pretendardCaption1.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale15.color)
        .padding(.horizontal, 17)
        .frame(height: 28)
        .background(ColorToken.mainAccent.color, in: Capsule())
    } else {
      CommunityPostInputSection(title: "카테고리", error: viewModel.state.visibleError(for: .category)) {
        TextField("카테고리", text: Binding(
          get: { viewModel.state.draft.category },
          set: { value in
            viewModel.updateCategory(value)
          }
        ))
        .submitLabel(.next)
        .focused($focusedField, equals: .category)
        .onTapGesture {
          focusedField = .category
          viewModel.markFieldFocused(.category)
        }
      }
    }
  }

  @ViewBuilder
  private var titleSection: some View {
    if viewModel.state.isDetail {
      Text(viewModel.state.post?.title ?? viewModel.state.draft.title)
        .font(TypographyToken.pretendardTitle1.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
    } else {
      CommunityPostInputSection(title: "제목", error: viewModel.state.visibleError(for: .title)) {
        TextField("제목", text: Binding(
          get: { viewModel.state.draft.title },
          set: { value in
            viewModel.updateTitle(value)
          }
        ))
        .submitLabel(.next)
        .focused($focusedField, equals: .title)
        .onTapGesture {
          focusedField = .title
          viewModel.markFieldFocused(.title)
        }
      }
    }
  }

  private var authorSummary: some View {
    HStack(spacing: 10) {
      CommunityPostAvatarView(url: viewModel.state.post?.creator.profileImageURL)

      VStack(alignment: .leading, spacing: 3) {
        Text(viewModel.state.post?.creator.nick ?? "나")
          .font(TypographyToken.pretendardBody2.font.weight(.bold))
          .foregroundStyle(ColorToken.grayScale0.color)

        Text(authorSubtext)
          .font(TypographyToken.pretendardCaption2.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .lineLimit(1)
      }
    }
  }

  private var authorSubtext: String {
    guard let creator = viewModel.state.post?.creator else {
      return "#사진 #보정"
    }

    if creator.hashTags.isEmpty == false {
      return creator.hashTags.joined(separator: " ")
    }

    return creator.introduction ?? "#사진 #보정"
  }

  @ViewBuilder
  private var bodySection: some View {
    if viewModel.state.isDetail {
      Text(viewModel.state.post?.content ?? viewModel.state.draft.content)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale45.color)
        .lineSpacing(6)
        .fixedSize(horizontal: false, vertical: true)
    } else {
      VStack(alignment: .leading, spacing: 6) {
        ZStack(alignment: .topLeading) {
          TextEditor(text: Binding(
            get: { viewModel.state.draft.content },
            set: { value in
              viewModel.updateContent(value)
            }
          ))
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale0.color)
          .scrollContentBackground(.hidden)
          .focused($focusedField, equals: .content)
          .padding(10)
          .frame(minHeight: 142)
          .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
          .onTapGesture {
            focusedField = .content
            viewModel.markFieldFocused(.content)
          }

          if viewModel.state.draft.content.isEmpty {
            Text("내용을 입력해주세요")
              .font(TypographyToken.pretendardBody2.font)
              .foregroundStyle(ColorToken.grayScale60.color)
              .padding(.horizontal, 16)
              .padding(.vertical, 18)
              .allowsHitTesting(false)
          }
        }

        HStack {
          if let error = viewModel.state.visibleError(for: .content) {
            Text(error)
              .foregroundStyle(ColorToken.mainAccent.color)
          }

          Spacer()

          Text("\(viewModel.state.draft.content.count.formatted(.number)) / \(CommunityPostState.contentLimit.formatted(.number))")
            .foregroundStyle(ColorToken.grayScale60.color)
        }
        .font(TypographyToken.pretendardCaption2.font)
      }
    }
  }

  @ViewBuilder
  private var imageSection: some View {
    if viewModel.state.isDetail {
      let attachments = viewModel.state.post?.attachments ?? []
      if attachments.isEmpty == false {
        CommunityReadOnlyAttachmentCarousel(attachments: attachments)
      }
    } else {
      CommunityEditableImageSectionView(
        existingFilePaths: viewModel.state.draft.existingFilePaths,
        selectedImages: viewModel.state.selectedImages,
        onSelectionChanged: { selections in
          Task {
            await viewModel.send(.imageSelectionChanged(selections))
          }
        },
        onRemoveExisting: { path in
          Task {
            await viewModel.send(.removeExistingImage(path))
          }
        }
      )
    }
  }

  @ViewBuilder
  private var metadataSection: some View {
    if viewModel.state.isDetail, let post = viewModel.state.post {
      HStack(spacing: 8) {
        Text(post.createdAt.communityPostDisplayDate)
        if post.updatedAt != post.createdAt {
          Text("수정")
        }
      }
      .font(TypographyToken.pretendardCaption2.font)
      .foregroundStyle(ColorToken.grayScale60.color)
    } else if viewModel.state.isDetail == false {
      VStack(alignment: .leading, spacing: 4) {
        Text(editorMetaText)
          .font(TypographyToken.pretendardCaption2.font)
          .foregroundStyle(ColorToken.grayScale60.color)
        if let errorMessage = viewModel.state.errorMessage {
          Text(errorMessage)
            .font(TypographyToken.pretendardCaption2.font)
            .foregroundStyle(ColorToken.mainAccent.color)
        }
      }
    }
  }

  private var editorMetaText: String {
    switch viewModel.state.mode {
    case .create:
      "임시 저장됨"
    case .edit:
      "수정 내용 저장 전"
    case .detail:
      ""
    }
  }

  private var actionBar: some View {
    HStack(spacing: 10) {
      CommunityPostActionButton(
        title: "좋아요 \(viewModel.state.post?.likeCount.formatted(.number) ?? "0")",
        systemImage: viewModel.state.post?.isLiked == true ? "heart.fill" : "heart",
        isPrimary: viewModel.state.post?.isLiked == true
      ) {
        Task {
          await viewModel.send(.likeTapped)
        }
      }

      CommunityPostActionButton(
        title: "댓글 \(viewModel.state.post?.commentCount.formatted(.number) ?? "0")",
        systemImage: "message.circle",
        isPrimary: false
      ) {}

      if viewModel.state.isOwner {
        CommunityPostActionButton(title: "수정", systemImage: nil, isPrimary: false) {
          Task {
            await viewModel.send(.editTapped)
          }
        }
        CommunityPostActionButton(title: "삭제", systemImage: nil, isPrimary: false) {
          Task {
            await viewModel.send(.deleteTapped)
          }
        }
      }
    }
    .frame(height: 44)
  }

  private var commentSection: some View {
    SharedCommentSectionView(
      comments: viewModel.state.post?.comments ?? [],
      expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
      replyingToCommentID: viewModel.state.replyingToCommentID,
      commentText: viewModel.state.commentText,
      onTextChanged: { text in
        viewModel.updateCommentText(text)
      },
      onSubmit: {
        Task {
          await viewModel.send(.submitComment)
        }
      },
      onReply: { commentID in
        Task {
          await viewModel.send(.replyTapped(commentID: commentID))
        }
      },
      onCancelReply: {
        Task {
          await viewModel.send(.cancelReply)
        }
      },
      onToggleReplies: { commentID in
        Task {
          await viewModel.send(.toggleReplies(commentID: commentID))
        }
      }
    )
  }

  private var stickyPrimaryAction: some View {
    Button {
      Task {
        await viewModel.send(.submit)
      }
    } label: {
      Text(viewModel.state.submitPhase == .submitting ? "등록" : viewModel.state.primaryActionTitle)
        .font(TypographyToken.pretendardBody1.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale15.color)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
          viewModel.state.canSubmit ? ColorToken.mainAccent.color : ColorToken.grayScale90.color,
          in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .buttonHitArea(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    .buttonStyle(.plain)
    .disabled(viewModel.state.canSubmit == false)
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .background(ColorToken.grayScale100.color)
  }
}

private struct CommunityPostInputSection<Content: View>: View {
  let title: String
  let error: String?
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(title)
        .font(TypographyToken.pretendardCaption1.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale30.color)

      content()
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

      if let error {
        Text(error)
          .font(TypographyToken.pretendardCaption2.font)
          .foregroundStyle(ColorToken.mainAccent.color)
      }
    }
  }
}

private struct CommunityEditableImageSectionView: View {
  let existingFilePaths: [String]
  let selectedImages: [PhotoPickerUploadSelection]
  let onSelectionChanged: ([PhotoPickerUploadSelection]) -> Void
  let onRemoveExisting: (String) -> Void

  @State private var pickerItems: [PhotosPickerItem] = []

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("사진 추가")
        .font(TypographyToken.pretendardCaption1.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale30.color)

      ScrollView(.horizontal) {
        HStack(spacing: 10) {
          ForEach(existingFilePaths, id: \.self) { path in
            CommunityExistingImageTileView(path: path) {
              onRemoveExisting(path)
            }
          }

          ForEach(selectedImages) { selection in
            CommunityLocalImageTileView(selection: selection)
          }

          PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: ImageUploadPreset.communityPost.maxCount,
            matching: .images
          ) {
            VStack(spacing: 8) {
              Image(systemName: "photo.badge.plus")
                .font(.system(size: 24, weight: .semibold))
              Text("사진 추가")
                .font(TypographyToken.pretendardCaption1.font.weight(.bold))
            }
            .foregroundStyle(ColorToken.grayScale45.color)
            .frame(width: max(existingFilePaths.isEmpty && selectedImages.isEmpty ? 350 : 116, 116), height: 116)
            .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ColorToken.grayScale90.color.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .onChange(of: pickerItems) { _, items in
      Task {
        var selections: [PhotoPickerUploadSelection] = []
        for (index, item) in items.prefix(ImageUploadPreset.communityPost.maxCount).enumerated() {
          guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
          selections.append(PhotoPickerUploadSelection(data: data, fileName: "post-image-\(index + 1).jpg"))
        }
        onSelectionChanged(selections)
      }
    }
  }
}

private struct CommunityExistingImageTileView: View {
  let path: String
  let onRemove: () -> Void

  var body: some View {
    ZStack(alignment: .topTrailing) {
      KFImage(AuthenticatedRemoteImageSupport.url(from: path))
        .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
        .placeholder {
          CommunityPostImagePlaceholderView()
        }
        .resizable()
        .scaledToFill()
        .frame(width: 116, height: 116)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

      Button(action: onRemove) {
        Image(systemName: "xmark")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(ColorToken.grayScale0.color)
          .frame(width: 24, height: 24)
          .background(ColorToken.brandBlackSprout.color.opacity(0.78), in: Circle())
      }
      .buttonStyle(.plain)
      .padding(6)
    }
  }
}

private struct CommunityLocalImageTileView: View {
  let selection: PhotoPickerUploadSelection

  var body: some View {
    Group {
      if let image = UIImage(data: selection.data) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        CommunityPostImagePlaceholderView()
      }
    }
    .frame(width: 116, height: 116)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}

private struct CommunityReadOnlyAttachmentCarousel: View {
  let attachments: [CommunityAttachment]
  @State private var currentIndex = 0

  var body: some View {
    TabView(selection: $currentIndex) {
      ForEach(Array(attachments.enumerated()), id: \.offset) { index, attachment in
        Group {
          switch attachment {
          case .image(let url):
            CommunityRemotePostImageView(url: url)
          case .video(let url):
            PostVideoPlayerView(url: url)
          }
        }
        .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: attachments.count > 1 ? .automatic : .never))
    .frame(height: 210)
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

private struct CommunityRemotePostImageView: View {
  let url: URL

  var body: some View {
    KFImage(url)
      .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
      .placeholder {
        CommunityPostImagePlaceholderView()
      }
      .resizable()
      .scaledToFill()
      .background(ColorToken.brandBlackSprout.color)
      .clipped()
  }
}

private struct CommunityPostImagePlaceholderView: View {
  var body: some View {
    ZStack {
      ColorToken.brandBlackSprout.color
      Image(systemName: "photo")
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(ColorToken.grayScale60.color)
    }
  }
}

private struct CommunityPostAvatarView: View {
  let url: URL?

  var body: some View {
    KFImage(url)
      .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
      .placeholder {
        Circle()
          .fill(ColorToken.brandBlackSprout.color)
          .overlay {
            Image(systemName: "person.fill")
              .font(.system(size: 16, weight: .regular))
              .foregroundStyle(ColorToken.grayScale60.color)
          }
      }
      .resizable()
      .scaledToFill()
      .frame(width: 36, height: 36)
      .clipShape(Circle())
  }
}

private struct CommunityPostActionButton: View {
  let title: String
  let systemImage: String?
  let isPrimary: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
        }
        Text(title)
          .font(TypographyToken.pretendardCaption1.font.weight(.bold))
      }
      .foregroundStyle(isPrimary ? ColorToken.grayScale15.color : ColorToken.grayScale45.color)
      .padding(.horizontal, 14)
      .frame(height: 42)
      .background(isPrimary ? ColorToken.mainAccent.color : ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      .buttonHitArea(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}

private struct CommunityPostLoadingView: View {
  let title: String

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(title)
        .font(.custom(TypographyToken.mulgyeolTitle1.fontName, size: 20, relativeTo: .headline))
        .foregroundStyle(ColorToken.grayScale30.color)
        .frame(maxWidth: .infinity, minHeight: 44)

      ForEach(0 ..< 7, id: \.self) { index in
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(ColorToken.brandBlackSprout.color)
          .frame(height: index == 3 ? 142 : 44)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 18)
  }
}

private struct CommunityPostErrorView: View {
  let title: String
  let message: String
  let retry: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      Text(title)
        .font(.custom(TypographyToken.mulgyeolTitle1.fontName, size: 20, relativeTo: .headline))
        .foregroundStyle(ColorToken.grayScale30.color)
        .frame(height: 44)

      Spacer()

      Text(message)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale45.color)

      Button(action: retry) {
        Text("다시 시도")
          .font(TypographyToken.pretendardBody2.font.weight(.bold))
          .foregroundStyle(ColorToken.grayScale15.color)
          .padding(.horizontal, 16)
          .frame(height: 42)
          .background(ColorToken.mainAccent.color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .buttonHitArea(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }

      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 18)
  }
}

private extension String {
  var communityPostDisplayDate: String {
    if let date = try? Date(self, strategy: .iso8601) {
      return date.formatted(date: .numeric, time: .omitted)
    }
    return self
  }
}
