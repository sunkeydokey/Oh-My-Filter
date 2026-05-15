import Kingfisher
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct CommunityPostView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: CommunityPostViewModel
  @FocusState private var focusedField: CommunityPostField?
  @State private var showLocalSaveToast = false
  @State private var showDetailSaveToast = false
  let navigate: (CommunityRoute) -> Void

  init(
    mode: CommunityPostMode,
    preloadedImages: [PhotoPickerUploadSelection] = [],
    mutationStore: CommunityPostMutationStore? = nil,
    navigate: @escaping (CommunityRoute) -> Void = { _ in }
  ) {
    _viewModel = State(initialValue: CommunityPostViewModel(
      mode: mode,
      preloadedImages: preloadedImages,
      mutationStore: mutationStore
    ))
    self.navigate = navigate
  }

  var body: some View {
    ZStack {
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

      if viewModel.state.showsDeleteConfirmation {
        CustomAlertView(
          title: "게시글 삭제",
          message: "게시글을 삭제할까요?",
          cancelTitle: "취소",
          confirmTitle: "삭제",
          onCancel: dismissDeleteConfirmation,
          onConfirm: confirmDelete
        )
      } else if viewModel.state.pendingDeleteCommentTarget != nil {
        CustomAlertView(
          title: "댓글 삭제",
          message: "댓글을 삭제할까요?",
          cancelTitle: "취소",
          confirmTitle: "삭제",
          onCancel: dismissDeleteCommentConfirmation,
          onConfirm: confirmDeleteComment
        )
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
    .onChange(of: viewModel.state.localSaveSucceeded) { _, succeeded in
      guard succeeded else { return }
      Task { await viewModel.send(.localSaveSucceededHandled) }
      showLocalSaveToast = true
      Task { try? await Task.sleep(for: .seconds(2)); showLocalSaveToast = false }
    }
    .onChange(of: viewModel.state.detailSavePhase) { _, phase in
      switch phase {
      case .saved:
        Task { await viewModel.send(.detailSavePhaseHandled) }
        showDetailSaveToast = true
        Task { try? await Task.sleep(for: .seconds(2)); showDetailSaveToast = false }
      case let .failed(message):
        Task {
          await viewModel.send(.detailSavePhaseHandled)
          await viewModel.send(.errorPresented(message))
        }
      default:
        break
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
    .alert(
      "오류",
      isPresented: Binding(
        get: { viewModel.state.errorMessage != nil },
        set: { isPresented in
          if isPresented == false {
            Task { await viewModel.send(.errorDismissed) }
          }
        }
      )
    ) {
      Button("확인", role: .cancel) {}
    } message: {
      Text(viewModel.state.errorMessage ?? "")
    }
    // Create/Edit: AnimeGAN 변환 시트
    .sheet(
      isPresented: Binding(
        get: { viewModel.state.isLocalAnimeSheetPresented },
        set: { isPresented in
          if !isPresented { Task { await viewModel.send(.animeConversionDismissed) } }
        }
      )
    ) {
      AnimeConversionPreviewSheet(
        state: viewModel.state.localAnimePreviewSheetState,
        onChoiceMade: { useConverted in
          Task { await viewModel.send(.animeConversionChoiceMade(useConverted: useConverted)) }
        },
        onDismiss: {
          Task { await viewModel.send(.animeConversionDismissed) }
        }
      )
      .presentationDetents([.large])
      .presentationBackground(ColorToken.brandBlackSprout.color)
    }
    // Detail: AnimeGAN 변환 후 저장 시트
    .sheet(
      isPresented: Binding(
        get: { viewModel.state.isDetailAnimeSheetPresented },
        set: { isPresented in
          if !isPresented { Task { await viewModel.send(.animeConversionDismissed) } }
        }
      )
    ) {
      AnimeConversionPreviewSheet(
        state: viewModel.state.detailAnimePreviewSheetState,
        onChoiceMade: { useConverted in
          if useConverted {
            Task { await viewModel.send(.saveAnimeResult) }
          } else {
            Task { await viewModel.send(.animeConversionDismissed) }
          }
        },
        onDismiss: {
          Task { await viewModel.send(.animeConversionDismissed) }
        }
      )
      .presentationDetents([.large])
      .presentationBackground(ColorToken.brandBlackSprout.color)
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
    .safeAreaInset(edge: .bottom) {
      if viewModel.state.isDetail == false {
        stickyPrimaryAction
      }
    }
    .overlay(alignment: .bottom) {
      if showLocalSaveToast || showDetailSaveToast {
        Text("사진이 저장되었습니다")
          .font(TypographyToken.pretendardCaption1.font.weight(.semibold))
          .foregroundStyle(ColorToken.grayScale0.color)
          .padding(.horizontal, 16)
          .frame(height: 40)
          .background(ColorToken.brandBlackSprout.color.opacity(0.88), in: Capsule())
          .padding(.bottom, 20)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.easeInOut(duration: 0.25), value: showLocalSaveToast || showDetailSaveToast)
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
        if viewModel.state.isMine {
          Menu {
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
          } label: {
            Image(systemName: "ellipsis")
              .font(.system(size: 20, weight: .semibold))
              .frame(width: 44, height: 44)
              .foregroundStyle(ColorToken.grayScale45.color)
          }
          .disabled(viewModel.state.isMine == false)
        }
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
        .foregroundStyle(ColorToken.grayScale100.color)
        .padding(.horizontal, 17)
        .frame(height: 28)
        .background(ColorToken.mainAccent.color, in: Capsule())
    } else {
      CommunityPostInputSection(title: "카테고리", error: viewModel.state.visibleError(for: .category)) {
        TextField("카테고리", text: Binding(
          get: { viewModel.state.draft.category },
          set: { value in
            Task { await viewModel.send(.categoryChanged(value)) }
          }
        ))
        .submitLabel(.next)
        .focused($focusedField, equals: .category)
        .onTapGesture {
          focusedField = .category
          Task { await viewModel.send(.fieldFocused(.category)) }
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
            Task { await viewModel.send(.titleChanged(value)) }
          }
        ))
        .submitLabel(.next)
        .focused($focusedField, equals: .title)
        .onTapGesture {
          focusedField = .title
          Task { await viewModel.send(.fieldFocused(.title)) }
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
              Task { await viewModel.send(.contentChanged(value)) }
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
            Task { await viewModel.send(.fieldFocused(.content)) }
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
        CommunityReadOnlyAttachmentCarousel(
          attachments: attachments,
          onSaveCurrentImage: { url in
            Task { await viewModel.send(.saveRemoteImageTapped(url: url)) }
          },
          onConvertCurrentImage: { url in
            Task { await viewModel.send(.convertRemoteImageToAnimeTapped(url: url)) }
          }
        )
      }
    } else {
      CommunityEditableImageSectionView(
        existingFilePaths: viewModel.state.draft.existingFilePaths,
        selectedImages: viewModel.state.selectedImages,
        convertingSelectionID: viewModel.state.convertingLocalSelectionID,
        onSelectionChanged: { selections in
          Task {
            await viewModel.send(.imageSelectionChanged(selections))
          }
        },
        onRemoveExisting: { path in
          Task {
            await viewModel.send(.removeExistingImage(path))
          }
        },
        onConvertToAnime: { selectionID in
          Task { await viewModel.send(.convertLocalImageToAnimeTapped(selectionID: selectionID)) }
        },
        onSaveLocalImage: { selectionID in
          Task { await viewModel.send(.saveLocalImageTapped(selectionID: selectionID)) }
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

      if viewModel.state.isMine {
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
      currentUserID: viewModel.state.currentUserID,
      expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
      replyingToCommentID: viewModel.state.replyingToCommentID,
      editingCommentTarget: viewModel.state.editingCommentTarget,
      commentText: viewModel.state.commentText,
      onTextChanged: { text in
        Task { await viewModel.send(.commentTextChanged(text)) }
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
      onCancelEdit: {
        Task {
          await viewModel.send(.cancelCommentEdit)
        }
      },
      onToggleReplies: { commentID in
        Task {
          await viewModel.send(.toggleReplies(commentID: commentID))
        }
      },
      onEditComment: { commentID in
        Task {
          await viewModel.send(.editCommentTapped(commentID: commentID))
        }
      },
      onDeleteComment: { commentID in
        Task {
          await viewModel.send(.deleteCommentTapped(commentID: commentID))
        }
      },
      onEditReply: { parentCommentID, replyID in
        Task {
          await viewModel.send(.editReplyTapped(parentCommentID: parentCommentID, replyID: replyID))
        }
      },
      onDeleteReply: { parentCommentID, replyID in
        Task {
          await viewModel.send(.deleteReplyTapped(parentCommentID: parentCommentID, replyID: replyID))
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
        .foregroundStyle(ColorToken.grayScale100.color)
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

  private func dismissDeleteConfirmation() {
    Task { await viewModel.send(.dismissDeleteConfirmation) }
  }

  private func confirmDelete() {
    Task { await viewModel.send(.deleteConfirmed) }
  }

  private func dismissDeleteCommentConfirmation() {
    Task { await viewModel.send(.dismissDeleteCommentConfirmation) }
  }

  private func confirmDeleteComment() {
    Task { await viewModel.send(.deleteCommentConfirmed) }
  }
}
