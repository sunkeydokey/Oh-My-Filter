import SwiftUI

struct ChatView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: ChatViewModel
  @State private var imagePreview: ChatImagePreview?
  @State private var isPresentingImageViewer = false
  @FocusState private var isComposerFocused: Bool
  @Environment(\.scenePhase) private var scenePhase

  init(
    room: ChatRoom,
    currentUserID: String,
    service: any ChatServicing,
    store: any ChatLocalStoring,
    socketManager: any ChatSocketManaging
  ) {
    _viewModel = State(
      initialValue: ChatViewModel(
        room: room,
        currentUserID: currentUserID,
        service: service,
        store: store,
        socketManager: socketManager
      )
    )
  }

  var body: some View {
    VStack(spacing: 16) {
      ChatHeaderView(
        title: viewModel.state.title,
        subtitle: subtitle,
        onBack: {
          Task { await viewModel.send(.disappear) }
          dismiss()
        }
      )

      ChatMessagesScrollView(
        messages: viewModel.state.messages,
        currentUserID: viewModel.state.currentUserID,
        onImageTapped: { files, index in
          isPresentingImageViewer = true
          imagePreview = ChatImagePreview(files: files, initialIndex: index)
        }
      )
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      ChatComposerView(
        selectedImages: viewModel.state.selectedImages,
        imageSelectionMessage: viewModel.state.imageSelectionMessage,
        composerText: viewModel.state.composerText,
        canSend: viewModel.state.canSend,
        isFocused: $isComposerFocused,
        onImageSelectionChanged: { selections in
          Task { await viewModel.send(.imageSelectionChanged(selections)) }
        },
        onComposerChanged: { text in
          Task { await viewModel.send(.composerChanged(text)) }
        },
        onSend: {
          Task { await viewModel.send(.sendTapped) }
        }
      )
    }
    .padding(.top, 18)
    .padding(.bottom, 12)
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
    .navigationBarBackButtonHidden()
    .toolbar(.hidden, for: .navigationBar)
    .task {
      await viewModel.send(.task)
    }
    .onChange(of: scenePhase) { _, newPhase in
      if newPhase == .active {
        Task { await viewModel.send(.enterForeground) }
      }
    }
    .onDisappear {
      guard isPresentingImageViewer == false else { return }
      Task { await viewModel.send(.disappear) }
    }
    .fullScreenCover(item: $imagePreview, onDismiss: {
      isPresentingImageViewer = false
    }) { preview in
      FullScreenImageViewer(
        files: preview.files,
        initialIndex: preview.initialIndex
      ) {
        imagePreview = nil
      }
    }
    .alert(
      "전송 실패",
      isPresented: Binding(
        get: { viewModel.state.alert != nil },
        set: { isPresented in
          if isPresented == false {
            Task { await viewModel.send(.deletePending) }
          }
        }
      ),
      presenting: viewModel.state.alert
    ) { _ in
      Button("삭제", role: .destructive) {
        Task { await viewModel.send(.deletePending) }
      }
      Button("다시 시도") {
        Task { await viewModel.send(.retryPending) }
      }
    } message: { alert in
      Text(alert.message)
    }
  }

  private var subtitle: String {
    switch viewModel.state.connectionState {
    case .idle, .syncing:
      return "동기화 중"
    case .connected:
      return "온라인"
    case .disconnected:
      return "오프라인"
    case .connecting:
      return "연결 중"
    case let .reconnecting(attempt):
      return "재연결 중 (\(attempt)회)"
    case .failed:
      return "연결 실패"
    }
  }
}

private struct ChatImagePreview: Identifiable, Equatable {
  let id = UUID()
  let files: [String]
  let initialIndex: Int
}
