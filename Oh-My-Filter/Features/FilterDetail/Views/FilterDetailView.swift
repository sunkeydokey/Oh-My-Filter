import Kingfisher
import PhotosUI
import SwiftUI

struct FilterDetailView: View {
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

      if let alert = viewModel.state.alert {
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
    .mulgyeolNavigationTitle(viewModel.state.detail?.title ?? "")
    .toolbarBackground(ColorToken.brandBlackSprout.color, for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbar {
      if viewModel.state.isMine {
        ToolbarItem(placement: .topBarTrailing) {
          Button("수정") {
            edit()
          }
          .font(TypographyToken.pretendardBody3.font)
          .foregroundStyle(ColorToken.mainAccent.color)
        }
      }
    }
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
    .onChange(of: pickerItems) { _, items in
      guard items.isEmpty == false else { return }
      Task {
        var dataList: [Data] = []
        for item in items {
          if let data = try? await item.loadTransferable(type: Data.self) {
            dataList.append(data)
          }
        }
        pickerItems = []
        if dataList.isEmpty == false {
          await viewModel.send(.photosSelected(dataList))
        }
      }
    }
    .photosPicker(
      isPresented: isPicking,
      selection: $pickerItems,
      maxSelectionCount: 5,
      selectionBehavior: .ordered,
      matching: .images
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
      .presentationDetents([.medium, .large])
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
    guard case let .readyToSave(images, _) = viewModel.state.applyPhotoPhase else { return [] }
    return images.enumerated().compactMap { index, cgImage -> PhotoPickerUploadSelection? in
      guard let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.9) else { return nil }
      return PhotoPickerUploadSelection(data: data, fileName: "filtered-\(index + 1).jpg")
    }
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
        expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
        replyingToCommentID: viewModel.state.replyingToCommentID,
        commentText: viewModel.state.commentText,
        action: downloadAction,
        onApply: applyAction,
        onPurchaseRequired: purchaseRequiredAction,
        onCommentTextChanged: commentTextChanged,
        onSubmitComment: submitComment,
        onReply: reply,
        onCancelReply: cancelReply,
        onToggleReplies: toggleReplies
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
        expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
        replyingToCommentID: viewModel.state.replyingToCommentID,
        commentText: viewModel.state.commentText,
        action: downloadAction,
        onApply: applyAction,
        onPurchaseRequired: purchaseRequiredAction,
        onCommentTextChanged: commentTextChanged,
        onSubmitComment: submitComment,
        onReply: reply,
        onCancelReply: cancelReply,
        onToggleReplies: toggleReplies
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
        expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
        replyingToCommentID: viewModel.state.replyingToCommentID,
        commentText: viewModel.state.commentText,
        action: downloadAction,
        onApply: applyAction,
        onPurchaseRequired: purchaseRequiredAction,
        onCommentTextChanged: commentTextChanged,
        onSubmitComment: submitComment,
        onReply: reply,
        onCancelReply: cancelReply,
        onToggleReplies: toggleReplies
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

  private func toggleReplies(commentID: String) {
    Task { await viewModel.send(.toggleReplies(commentID: commentID)) }
  }

  private func edit() {
    Task { await viewModel.send(.tapEdit) }
  }

  private func dismissAlert() {
    Task { await viewModel.send(.dismissAlert) }
  }

  private func confirmAlert() {
    Task { await viewModel.send(.confirmAlert) }
  }
}
