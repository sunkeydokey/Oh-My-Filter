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
    .navigationTitle(viewModel.state.detail?.title ?? "")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if let title = viewModel.state.detail?.title {
        ToolbarItem(placement: .principal) {
          Text(title)
            .font(TypographyToken.mulgyeolBody1.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .id("FilterDetailTitle-\(title)")
        }
      }
    }
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
        action: downloadAction
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
        action: downloadAction
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
        action: downloadAction
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
