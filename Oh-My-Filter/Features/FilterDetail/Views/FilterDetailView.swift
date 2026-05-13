import Kingfisher
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct FilterDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: FilterDetailViewModel
  @State private var didLoad = false
  @State private var pickerItems: [PhotosPickerItem] = []
  private let navigate: (MainRoute) -> Void

  init(
    filterID: String,
    navigate: @escaping (MainRoute) -> Void = { _ in }
  ) {
    _viewModel = State(initialValue: FilterDetailViewModel(filterID: filterID))
    self.navigate = navigate
  }

  var body: some View {
    ZStack {
      content
        .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
        .screenCaptureProtected(!viewModel.state.isOwned)
        .safeAreaInset(edge: .top) {
          CustomStackNavigationHeader(
            title: viewModel.state.detail?.title ?? "",
            onBack: { dismiss() }
          ) {
            if viewModel.state.isMine {
              Menu {
                Button("수정", action: edit)
                Button("삭제", role: .destructive, action: deleteFilter)
              } label: {
                Image(systemName: "ellipsis")
                  .font(.system(size: 20, weight: .semibold))
                  .foregroundStyle(ColorToken.grayScale45.color)
              }
            } else {
              Color.clear
            }
          }
          .padding(.horizontal, 20)
          .background(ColorToken.brandBlackSprout.color)
        }

      if viewModel.state.showsDeleteFilterConfirmation {
        CustomAlertView(
          title: "필터 삭제",
          message: "필터를 삭제할까요?",
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
      } else if let alert = viewModel.state.alert {
        CustomAlertView(
          title: alert.title,
          message: alert.message,
          cancelTitle: alert.cancelTitle,
          confirmTitle: alert.confirmTitle,
          onCancel: dismissAlert,
          onConfirm: confirmAlert
        )
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .swipeBackEnabled()
    .task {
      guard didLoad == false else { return }
      didLoad = true
      await viewModel.send(.task)
    }
    .onChange(of: viewModel.state.route) { _, route in
      guard case let .update(draft)? = route else { return }
      navigate(.filterUpdate(draft))
      Task { await viewModel.send(.routeHandled) }
    }
    .onChange(of: viewModel.state.shouldDismiss) { _, shouldDismiss in
      guard shouldDismiss else { return }
      dismiss()
      Task { await viewModel.send(.dismissHandled) }
    }
    .onChange(of: pickerItems) { _, items in
      guard items.isEmpty == false else { return }
      Task {
        var inputs: [FilterMediaInput] = []
        for (index, item) in items.enumerated() {
          if let data = try? await item.loadTransferable(type: Data.self) {
            inputs.append(mediaInput(from: item, data: data, index: index))
          }
        }
        pickerItems = []
        if inputs.isEmpty == false {
          await viewModel.send(.mediaSelected(inputs))
        }
      }
    }
    .photosPicker(
      isPresented: isPicking,
      selection: $pickerItems,
      maxSelectionCount: 5,
      selectionBehavior: .ordered,
      matching: .any(of: [.images, .videos])
    )
    .sheet(isPresented: isApplySheetPresented) {
      FilterApplyProgressSheet(
        phase: viewModel.state.applyPhotoPhase,
        boastPreloadedImages: currentBoastPreloadedImages,
        onSaveCurrent: saveCurrentFilteredImage,
        onSaveAll: saveAllFilteredImages,
        onDismiss: dismissApplySheet,
        onIndexChanged: previewIndexChanged
      )
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
    // 커뮤니티 탭 전환 방식 (추후 취사 선택용, 현재 비활성)
    // case let .boast(prefilledImages):
    //   navigate(.communityPostCreate(prefilledImages: prefilledImages))
    //   Task { await viewModel.send(.boastRouteHandled) }
    .sheet(item: paymentRequestBinding) { paymentRequest in
      PortoneWebView(paymentRequest: paymentRequest) { response in
        Task {
          await viewModel.send(.paymentResponseReceived(response))
        }
      }
    }
  }

  private var isPicking: Binding<Bool> {
    Binding {
      viewModel.state.applyPhotoPhase == .picking
    } set: { isPresented in
      if !isPresented && viewModel.state.applyPhotoPhase == .picking {
        Task { await viewModel.send(.dismissApplySheet) }
      }
    }
  }

  private var isApplySheetPresented: Binding<Bool> {
    Binding {
      switch viewModel.state.applyPhotoPhase {
      case .rendering, .readyToSave, .saving, .saved, .failed:
        true
      default:
        false
      }
    } set: { isPresented in
      if !isPresented {
        Task { await viewModel.send(.dismissApplySheet) }
      }
    }
  }

  private var currentBoastPreloadedImages: [PhotoPickerUploadSelection] {
    guard case let .readyToSave(outputs, _) = viewModel.state.applyPhotoPhase else { return [] }
    return outputs.map(\.uploadSelection)
  }

  private func mediaInput(from item: PhotosPickerItem, data: Data, index: Int) -> FilterMediaInput {
    let contentType = item.supportedContentTypes.first(where: { $0.conforms(to: .movie) })
      ?? item.supportedContentTypes.first
    let isVideo = contentType?.conforms(to: .movie) == true
    let fileExtension = contentType?.preferredFilenameExtension ?? (isVideo ? "mov" : "jpg")
    let mimeType = contentType?.preferredMIMEType ?? (isVideo ? "video/quicktime" : "image/jpeg")
    return FilterMediaInput(
      data: data,
      fileName: "selected-\(index + 1).\(fileExtension)",
      kind: isVideo ? .video : .image,
      mimeType: mimeType
    )
  }

  private var paymentRequestBinding: Binding<PortonePaymentRequest?> {
    Binding {
      viewModel.state.paymentRequest
    } set: { paymentRequest in
      guard paymentRequest == nil else { return }
      Task {
        await viewModel.send(.dismissPaymentSheet)
      }
    }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state.phase {
    case .idle, .loading(previous: nil):
      FilterDetailLoadingView()
    case let .loading(previous?):
      FilterDetailLoadedView(
        detail: previous,
        previewState: .fallback(
          originalImageURL: previous.originalImageURL,
          filteredImageURL: previous.fallbackFilteredImageURL
        ),
        isPaymentProcessing: viewModel.state.isPaymentProcessing,
        isMine: viewModel.state.isMine,
        currentUserID: viewModel.state.currentUserID,
        expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
        replyingToCommentID: viewModel.state.replyingToCommentID,
        editingCommentTarget: viewModel.state.editingCommentTarget,
        commentText: viewModel.state.commentText,
        onToggleLike: toggleLike,
        action: downloadAction,
        onApply: applyAction,
        onPurchaseRequired: purchaseRequiredAction,
        onCommentTextChanged: commentTextChanged,
        onSubmitComment: submitComment,
        onReply: reply,
        onCancelReply: cancelReply,
        onCancelCommentEdit: cancelCommentEdit,
        onToggleReplies: toggleReplies,
        onEditComment: editComment,
        onDeleteComment: deleteComment,
        onEditReply: editReply,
        onDeleteReply: deleteReply
      )
      .overlay {
        ProgressView()
          .tint(ColorToken.mainAccent.color)
      }
    case let .loaded(detail, previewState):
      FilterDetailLoadedView(
        detail: detail,
        previewState: previewState,
        isPaymentProcessing: viewModel.state.isPaymentProcessing,
        isMine: viewModel.state.isMine,
        currentUserID: viewModel.state.currentUserID,
        expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
        replyingToCommentID: viewModel.state.replyingToCommentID,
        editingCommentTarget: viewModel.state.editingCommentTarget,
        commentText: viewModel.state.commentText,
        onToggleLike: toggleLike,
        action: downloadAction,
        onApply: applyAction,
        onPurchaseRequired: purchaseRequiredAction,
        onCommentTextChanged: commentTextChanged,
        onSubmitComment: submitComment,
        onReply: reply,
        onCancelReply: cancelReply,
        onCancelCommentEdit: cancelCommentEdit,
        onToggleReplies: toggleReplies,
        onEditComment: editComment,
        onDeleteComment: deleteComment,
        onEditReply: editReply,
        onDeleteReply: deleteReply
      )
    case let .failed(message, previous: nil):
      FilterDetailErrorView(message: message, retryAction: retry)
    case let .failed(message, previous?):
      FilterDetailLoadedView(
        detail: previous,
        previewState: .fallback(
          originalImageURL: previous.originalImageURL,
          filteredImageURL: previous.fallbackFilteredImageURL
        ),
        isPaymentProcessing: viewModel.state.isPaymentProcessing,
        isMine: viewModel.state.isMine,
        currentUserID: viewModel.state.currentUserID,
        expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
        replyingToCommentID: viewModel.state.replyingToCommentID,
        editingCommentTarget: viewModel.state.editingCommentTarget,
        commentText: viewModel.state.commentText,
        onToggleLike: toggleLike,
        action: downloadAction,
        onApply: applyAction,
        onPurchaseRequired: purchaseRequiredAction,
        onCommentTextChanged: commentTextChanged,
        onSubmitComment: submitComment,
        onReply: reply,
        onCancelReply: cancelReply,
        onCancelCommentEdit: cancelCommentEdit,
        onToggleReplies: toggleReplies,
        onEditComment: editComment,
        onDeleteComment: deleteComment,
        onEditReply: editReply,
        onDeleteReply: deleteReply
      )
      .overlay(alignment: .top) {
        Text(message)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale0.color)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(ColorToken.grayScale90.color, in: Capsule())
          .padding(.top, 12)
      }
    }
  }

  private func retry() {
    Task { await viewModel.send(.retry) }
  }

  private func downloadAction() {
    Task { await viewModel.send(.tapDownload) }
  }

  private func toggleLike() {
    Task { await viewModel.send(.likeTapped) }
  }

  private func applyAction() {
    Task { await viewModel.send(.tapApply) }
  }

  private func purchaseRequiredAction() {
    Task { await viewModel.send(.tapPurchaseRequired) }
  }

  private func saveCurrentFilteredImage() {
    Task { await viewModel.send(.saveCurrentFilteredImage) }
  }

  private func saveAllFilteredImages() {
    Task { await viewModel.send(.saveAllFilteredImages) }
  }

  private func previewIndexChanged(_ index: Int) {
    Task { await viewModel.send(.previewIndexChanged(index)) }
  }

  private func dismissApplySheet() {
    Task { await viewModel.send(.dismissApplySheet) }
  }

  private func commentTextChanged(_ text: String) {
    Task { await viewModel.send(.commentTextChanged(text)) }
  }

  private func submitComment() {
    Task { await viewModel.send(.submitComment) }
  }

  private func reply(commentID: String) {
    Task { await viewModel.send(.replyTapped(commentID: commentID)) }
  }

  private func cancelReply() {
    Task { await viewModel.send(.cancelReply) }
  }

  private func cancelCommentEdit() {
    Task { await viewModel.send(.cancelCommentEdit) }
  }

  private func toggleReplies(commentID: String) {
    Task { await viewModel.send(.toggleReplies(commentID: commentID)) }
  }

  private func editComment(commentID: String) {
    Task { await viewModel.send(.editCommentTapped(commentID: commentID)) }
  }

  private func deleteComment(commentID: String) {
    Task { await viewModel.send(.deleteCommentTapped(commentID: commentID)) }
  }

  private func editReply(parentCommentID: String, replyID: String) {
    Task { await viewModel.send(.editReplyTapped(parentCommentID: parentCommentID, replyID: replyID)) }
  }

  private func deleteReply(parentCommentID: String, replyID: String) {
    Task { await viewModel.send(.deleteReplyTapped(parentCommentID: parentCommentID, replyID: replyID)) }
  }

  private func edit() {
    Task { await viewModel.send(.tapEdit) }
  }

  private func deleteFilter() {
    Task { await viewModel.send(.tapDelete) }
  }

  private func dismissAlert() {
    Task { await viewModel.send(.dismissAlert) }
  }

  private func confirmAlert() {
    Task { await viewModel.send(.confirmAlert) }
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
