import Kingfisher
import SwiftUI
import UIKit

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
    .padding(.horizontal, 20)
  }

  private var messages: some View {
    ChatMessagesScrollView(
      messages: viewModel.state.messages,
      currentUserID: viewModel.state.currentUserID,
      onImageTapped: { files, index in
        isPresentingImageViewer = true
        imagePreview = ChatImagePreview(files: files, initialIndex: index)
      }
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    .padding(.horizontal, 20)
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

private struct ChatMessagesScrollView: UIViewRepresentable {
  let messages: [ChatMessage]
  let currentUserID: String
  let onImageTapped: ([String], Int) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(
      currentMessageCount: messages.count,
      onImageTapped: onImageTapped
    )
  }

  func makeUIView(context: Context) -> ChatPreservingScrollView {
    let scrollView = ChatPreservingScrollView()
    scrollView.backgroundColor = .clear
    scrollView.alwaysBounceVertical = true
    scrollView.isScrollEnabled = true
    scrollView.keyboardDismissMode = .none
    scrollView.showsVerticalScrollIndicator = true
    scrollView.indicatorStyle = .white
    scrollView.delegate = context.coordinator

    let hostingController = UIHostingController(rootView: AnyView(content(context: context)))
    hostingController.view.backgroundColor = .clear
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    hostingController.view.setContentHuggingPriority(.required, for: .vertical)
    hostingController.view.setContentCompressionResistancePriority(.required, for: .vertical)

    scrollView.addSubview(hostingController.view)
    scrollView.hostedView = hostingController.view
    scrollView.measureContentHeight = { [weak hostingController] width in
      let height = hostingController?.sizeThatFits(
        in: CGSize(width: width, height: .greatestFiniteMagnitude)
      ).height ?? 0
      return height
    }
    context.coordinator.hostingController = hostingController
    context.coordinator.scrollView = scrollView
    context.coordinator.requestScrollToBottom(animated: false)
    return scrollView
  }

  func updateUIView(_ scrollView: ChatPreservingScrollView, context: Context) {
    context.coordinator.onImageTapped = onImageTapped
    context.coordinator.hostingController?.rootView = AnyView(content(context: context))
    context.coordinator.hostingController?.view.invalidateIntrinsicContentSize()
    scrollView.setNeedsLayout()

    let shouldScrollToBottom = messages.count != context.coordinator.currentMessageCount
    context.coordinator.currentMessageCount = messages.count

    if shouldScrollToBottom {
      context.coordinator.requestScrollToBottom(animated: true)
    }
  }

  private func content(context: Context) -> some View {
    VStack(spacing: 12) {
      ForEach(messages) { message in
        ChatMessageBubbleView(
          message: message,
          isMine: message.sender.id == currentUserID
        ) { files, index in
          context.coordinator.onImageTapped(files, index)
        }
        .id(message.id)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 4)
    .frame(maxWidth: .infinity)
    .fixedSize(horizontal: false, vertical: true)
  }

  final class Coordinator: NSObject, UIScrollViewDelegate {
    var currentMessageCount: Int
    var onImageTapped: ([String], Int) -> Void
    var hostingController: UIHostingController<AnyView>?
    weak var scrollView: ChatPreservingScrollView?

    init(
      currentMessageCount: Int,
      onImageTapped: @escaping ([String], Int) -> Void
    ) {
      self.currentMessageCount = currentMessageCount
      self.onImageTapped = onImageTapped
    }

    func requestScrollToBottom(animated: Bool) {
      Task { @MainActor [weak self] in
        await Task.yield()
        self?.scrollView?.scrollToBottom(animated: animated)
      }
    }
  }
}

private final class ChatPreservingScrollView: UIScrollView {
  weak var hostedView: UIView?
  var measureContentHeight: ((CGFloat) -> CGFloat)?

  private var previousBoundsHeight: CGFloat = 0
  private var previousContentHeight: CGFloat = 0
  private var pendingBottomGap: CGFloat?

  override func layoutSubviews() {
    let bottomGap = pendingBottomGap ?? transitionBottomGap

    super.layoutSubviews()

    updateHostedViewLayout()

    let didChangeViewportHeight = previousBoundsHeight > 0 && abs(bounds.height - previousBoundsHeight) > 0.5
    let didChangeContentHeight = previousContentHeight > 0 && abs(contentSize.height - previousContentHeight) > 0.5
    if pendingBottomGap != nil || didChangeViewportHeight || didChangeContentHeight {
      let targetOffsetY = contentSize.height - bounds.height + adjustedContentInset.bottom - bottomGap
      let clampedOffsetY = clampedOffsetY(targetOffsetY)
      setContentOffset(CGPoint(x: contentOffset.x, y: clampedOffsetY), animated: false)
      pendingBottomGap = nil
    }

    previousBoundsHeight = bounds.height
    previousContentHeight = contentSize.height
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    NotificationCenter.default.removeObserver(self)

    if window == nil {
      pendingBottomGap = nil
    } else {
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(keyboardWillChangeFrame),
        name: UIResponder.keyboardWillChangeFrameNotification,
        object: nil
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(keyboardWillChangeFrame),
        name: UIResponder.keyboardWillHideNotification,
        object: nil
      )
    }
  }

  func scrollToBottom(animated: Bool) {
    layoutIfNeeded()
    let targetOffsetY = contentSize.height - bounds.height + adjustedContentInset.bottom
    let clampedOffsetY = clampedOffsetY(targetOffsetY)
    setContentOffset(CGPoint(x: contentOffset.x, y: clampedOffsetY), animated: animated)
  }

  @objc private func keyboardWillChangeFrame(_ notification: Notification) {
    pendingBottomGap = transitionBottomGap
    setNeedsLayout()
  }

  private var currentBottomGap: CGFloat {
    max(0, contentSize.height - bounds.height - contentOffset.y + adjustedContentInset.bottom)
  }

  private var previousLayoutBottomGap: CGFloat {
    guard previousBoundsHeight > 0 else { return currentBottomGap }
    return max(0, previousContentHeight - previousBoundsHeight - contentOffset.y + adjustedContentInset.bottom)
  }

  private var transitionBottomGap: CGFloat {
    min(currentBottomGap, previousLayoutBottomGap)
  }

  private func updateHostedViewLayout() {
    guard let hostedView else { return }

    hostedView.frame.size.width = bounds.width
    hostedView.setNeedsLayout()
    hostedView.layoutIfNeeded()

    let measuredHeight = measureContentHeight?(bounds.width) ?? 0
    let contentHeight = max(0, measuredHeight)
    hostedView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: contentHeight)
    contentSize = CGSize(width: bounds.width, height: contentHeight)
  }

  private func clampedOffsetY(_ offsetY: CGFloat) -> CGFloat {
    let minimumOffsetY = -adjustedContentInset.top
    let maximumOffsetY = max(minimumOffsetY, contentSize.height - bounds.height + adjustedContentInset.bottom)
    return min(maximumOffsetY, max(minimumOffsetY, offsetY))
  }

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
    .frame(width: 220, height: 180)
    .clipShape(.rect(cornerRadius: 12))
    .contentShape(.rect(cornerRadius: 12))
    .overlay {
      RoundedRectangle(cornerRadius: 12)
        .stroke(ColorToken.grayScale90.color.opacity(0.45), lineWidth: 1)
    }
    .onTapGesture {
      onTap()
    }
    .accessibilityAddTraits(.isButton)
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
