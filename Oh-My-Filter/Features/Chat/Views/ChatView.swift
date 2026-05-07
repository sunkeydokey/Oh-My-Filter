import Kingfisher
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
      header
      messages
      composer
    }
    .padding(.horizontal, 20)
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
    .alert("전송 실패", isPresented: Binding(
      get: { viewModel.state.alert != nil },
      set: { isPresented in
        if isPresented == false {
          Task { await viewModel.send(.deletePending) }
        }
      }
    ), presenting: viewModel.state.alert) { _ in
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

  private var header: some View {
    HStack(spacing: 12) {
      Button {
        Task { await viewModel.send(.disappear) }
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(ColorToken.grayScale0.color)
          .frame(width: 40, height: 40)
          .background(ColorToken.grayScale100.color, in: .rect(cornerRadius: 20))
          .overlay {
            RoundedRectangle(cornerRadius: 20)
              .stroke(ColorToken.grayScale90.color.opacity(0.5), lineWidth: 1)
          }
      }

      ChatAvatarView(text: viewModel.state.title, size: 48)

      VStack(alignment: .leading, spacing: 2) {
        Text(viewModel.state.title)
          .font(TypographyToken.mulgyeolBody1.font)
          .foregroundStyle(ColorToken.grayScale0.color)
          .lineLimit(1)

        Text(subtitle)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(height: 64)
  }

  private var messages: some View {
    ScrollViewReader { proxy in
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(viewModel.state.messages) { message in
            ChatMessageBubbleView(
              message: message,
              isMine: message.sender.id == viewModel.state.currentUserID
            ) { files, index in
              isPresentingImageViewer = true
              imagePreview = ChatImagePreview(files: files, initialIndex: index)
            }
            .id(message.id)
          }
        }
        .padding(.vertical, 4)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .onChange(of: viewModel.state.messages.count) { _, _ in
        scrollToBottom(proxy)
      }
      .onAppear {
        scrollToBottom(proxy)
      }
    }
  }

  private var composer: some View {
    VStack(alignment: .leading, spacing: 10) {
      PhotoPickerUploadView(
        preset: .chat,
        selections: Binding(
          get: { viewModel.state.selectedImages },
          set: { selections in Task { await viewModel.send(.imageSelectionChanged(selections)) } }
        )
      )

      if let imageSelectionMessage = viewModel.state.imageSelectionMessage {
        Text(imageSelectionMessage)
          .font(TypographyToken.pretendardCaption2.font)
          .foregroundStyle(ColorToken.mainAccent.color)
      }

      HStack(alignment: .bottom, spacing: 12) {
        TextField("메시지를 입력하세요...", text: Binding(
          get: { viewModel.state.composerText },
          set: { text in Task { await viewModel.send(.composerChanged(text)) } }
        ), axis: .vertical)
        .lineLimit(1...3)
        .focused($isComposerFocused)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()

        Button {
          Task { await viewModel.send(.sendTapped) }
        } label: {
          Image(systemName: "arrow.up")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(ColorToken.brandBlackSprout.color)
            .frame(width: 40, height: 40)
            .background(
              viewModel.state.canSend ? ColorToken.mainAccent.color : ColorToken.grayScale75.color,
              in: .rect(cornerRadius: 20)
            )
        }
        .disabled(viewModel.state.canSend == false)
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(ColorToken.grayScale100.color, in: .rect(cornerRadius: 18))
    .overlay {
      RoundedRectangle(cornerRadius: 18)
        .stroke(ColorToken.grayScale90.color.opacity(0.5), lineWidth: 1)
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

  private func scrollToBottom(_ proxy: ScrollViewProxy) {
    guard let lastID = viewModel.state.messages.last?.id else { return }
    withAnimation(.snappy) {
      proxy.scrollTo(lastID, anchor: .bottom)
    }
  }
}

private struct ChatImagePreview: Identifiable, Equatable {
  let id = UUID()
  let files: [String]
  let initialIndex: Int
}

private struct ChatMessageBubbleView: View {
  let message: ChatMessage
  let isMine: Bool
  let onImageTapped: ([String], Int) -> Void

  var body: some View {
    HStack {
      if isMine {
        Spacer(minLength: 44)
      }

      VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
        if message.files.isEmpty == false {
          ChatMessageImagePreviewView(files: message.files) {
            onImageTapped(message.files, 0)
          }
        }

        if shouldShowText {
          Text(message.content)
            .font(TypographyToken.pretendardBody3.font.weight(isMine ? .semibold : .regular))
            .foregroundStyle(isMine ? ColorToken.brandBlackSprout.color : ColorToken.grayScale0.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: 260, alignment: .leading)
            .background(isMine ? ColorToken.mainAccent.color : ColorToken.grayScale100.color, in: .rect(cornerRadius: 12))
            .overlay {
              if isMine == false {
                RoundedRectangle(cornerRadius: 12)
                  .stroke(ColorToken.grayScale90.color.opacity(0.5), lineWidth: 1)
              }
            }
        }

        Text(messageDate(message.createdAt))
          .font(TypographyToken.pretendardCaption2.font)
          .foregroundStyle(ColorToken.grayScale60.color)
      }

      if isMine == false {
        Spacer(minLength: 44)
      }
    }
    .frame(maxWidth: .infinity)
  }

  private var shouldShowText: Bool {
    message.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
  }

  private func messageDate(_ date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
      return date.formatted(date: .omitted, time: .shortened)
    }
    return date.formatted(date: .abbreviated, time: .shortened)
  }
}

private struct ChatMessageImagePreviewView: View {
  let files: [String]
  let onTap: () -> Void

  var body: some View {
    Button {
      onTap()
    } label: {
      ZStack(alignment: .bottomTrailing) {
        Group {
          if let url = AuthenticatedRemoteImageSupport.url(from: files.first) {
            KFImage(url)
              .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
              .placeholder {
                imagePlaceholder
              }
              .resizable()
              .scaledToFill()
          } else {
            imagePlaceholder
          }
        }
        .frame(width: 220, height: 180)
        .clipped()

        Text("1 / \(files.count)")
          .font(TypographyToken.pretendardCaption2.font.weight(.semibold))
          .foregroundStyle(ColorToken.grayScale0.color)
          .padding(.horizontal, 8)
          .frame(height: 26)
          .background(ColorToken.brandBlackSprout.color.opacity(0.72), in: Capsule())
          .padding(8)
      }
      .clipShape(.rect(cornerRadius: 12))
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .stroke(ColorToken.grayScale90.color.opacity(0.45), lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
  }

  private var imagePlaceholder: some View {
    ZStack {
      ColorToken.grayScale90.color
      Image(systemName: "photo")
        .font(.system(size: 28, weight: .regular))
        .foregroundStyle(ColorToken.grayScale45.color)
    }
  }
}
