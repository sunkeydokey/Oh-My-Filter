import Kingfisher
import SwiftUI

struct FilterDetailView: View {
  @State private var viewModel: FilterDetailViewModel
  @State private var didLoad = false

  init(filterID: String) {
    _viewModel = State(initialValue: FilterDetailViewModel(filterID: filterID))
  }

  var body: some View {
    ZStack {
      content
        .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())

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
    .task {
      guard didLoad == false else { return }
      didLoad = true
      await viewModel.send(.task)
    }
    .sheet(item: paymentRequestBinding) { paymentRequest in
      PortoneWebView(paymentRequest: paymentRequest) { response in
        Task {
          await viewModel.send(.paymentResponseReceived(response))
        }
      }
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
        expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
        replyingToCommentID: viewModel.state.replyingToCommentID,
        commentText: viewModel.state.commentText,
        action: downloadAction,
        onCommentTextChanged: commentTextChanged,
        onSubmitComment: submitComment,
        onReply: reply,
        onCancelReply: cancelReply,
        onToggleReplies: toggleReplies
      )
      .overlay {
        ProgressView()
          .tint(ColorToken.sesacFilterBrightTurquoise.color)
      }
    case let .loaded(detail, previewState):
      FilterDetailLoadedView(
        detail: detail,
        previewState: previewState,
        isPaymentProcessing: viewModel.state.isPaymentProcessing,
        expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
        replyingToCommentID: viewModel.state.replyingToCommentID,
        commentText: viewModel.state.commentText,
        action: downloadAction,
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
        expandedReplyCommentIDs: viewModel.state.expandedReplyCommentIDs,
        replyingToCommentID: viewModel.state.replyingToCommentID,
        commentText: viewModel.state.commentText,
        action: downloadAction,
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
    Task {
      await viewModel.send(.retry)
    }
  }

  private func downloadAction() {
    Task {
      await viewModel.send(.tapDownload)
    }
  }

  private func commentTextChanged(_ text: String) {
    Task {
      await viewModel.send(.commentTextChanged(text))
    }
  }

  private func submitComment() {
    Task {
      await viewModel.send(.submitComment)
    }
  }

  private func reply(commentID: String) {
    Task {
      await viewModel.send(.replyTapped(commentID: commentID))
    }
  }

  private func cancelReply() {
    Task {
      await viewModel.send(.cancelReply)
    }
  }

  private func toggleReplies(commentID: String) {
    Task {
      await viewModel.send(.toggleReplies(commentID: commentID))
    }
  }

  private func dismissAlert() {
    Task {
      await viewModel.send(.dismissAlert)
    }
  }

  private func confirmAlert() {
    Task {
      await viewModel.send(.confirmAlert)
    }
  }
}
