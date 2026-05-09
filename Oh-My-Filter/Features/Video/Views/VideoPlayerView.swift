import AVFoundation
import Kingfisher
import SwiftUI
import UIKit

struct VideoPlayerView: View {
  @State private var viewModel: VideoPlayerViewModel
  @Environment(\.dismiss) private var dismiss
  @Environment(\.scenePhase) private var scenePhase

  private static let cardBackground = Color(red: 20 / 255, green: 20 / 255, blue: 26 / 255)
  private static let cardStroke = Color(red: 38 / 255, green: 38 / 255, blue: 43 / 255).opacity(0.5)

  init(video: CommunityVideo) {
    _viewModel = State(wrappedValue: VideoPlayerViewModel(video: video))
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        navigationBar
        playerContainer
        coreMetadata
        actionRow
        expandableDescription
        subtitleSection
        qualitySection
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 24)
    }
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .fullScreenCover(isPresented: fullScreenBinding) {
      fullScreenPlayer
    }
    .onChange(of: viewModel.isFullScreenPresented) { _, isFullScreen in
      requestOrientation(isFullScreen ? .landscape : .portrait)
    }
    .onChange(of: scenePhase) { _, newPhase in
      Task {
        switch newPhase {
        case .background: await viewModel.send(.enterBackground)
        case .inactive:   await viewModel.send(.becomeInactive)
        case .active:     await viewModel.send(.enterForeground)
        @unknown default: break
        }
      }
    }
    .task { await viewModel.send(.task) }
  }

  private var fullScreenBinding: Binding<Bool> {
    Binding {
      viewModel.isFullScreenPresented
    } set: { isPresented in
      guard isPresented == false else { return }
      Task { await viewModel.send(.exitFullScreen) }
    }
  }

  // MARK: - Navigation Bar

  private var navigationBar: some View {
    HStack {
      Button {
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(ColorToken.grayScale30.color)
      }

      Spacer()

      Text("Video")
        .font(TypographyToken.mulgyeolBody1.font)
        .foregroundStyle(ColorToken.grayScale60.color)

      Spacer()

      Image(systemName: "ellipsis")
        .font(.system(size: 22, weight: .medium))
        .foregroundStyle(ColorToken.grayScale60.color)
    }
    .frame(height: 44)
  }

  // MARK: - Player Container

  private var playerContainer: some View {
    ZStack {
      switch viewModel.playerPhase {
      case .loading:
        loadingPlayer
      case .error:
        errorPlayer
      case .ready:
        readyPlayer
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 197)
    .background(ColorToken.brandBlackSprout.color)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private var loadingPlayer: some View {
    VStack(spacing: 12) {
      ProgressView()
        .tint(ColorToken.grayScale75.color)
        .scaleEffect(1.3)
      Text("비디오를 불러오는 중")
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale60.color)
    }
  }

  private var errorPlayer: some View {
    VStack(spacing: 12) {
      Image(systemName: "exclamationmark.circle")
        .font(.system(size: 34))
        .foregroundStyle(ColorToken.grayScale75.color)
      if case let .error(message) = viewModel.playerPhase {
        Text(message)
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale30.color)
      }
      Button {
        Task { await viewModel.send(.retry) }
      } label: {
        Text("다시 시도")
          .font(TypographyToken.pretendardBody3.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .padding(.horizontal, 14)
          .frame(height: 34)
          .background(ColorToken.mainAccent.color)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
    }
  }

  private var readyPlayer: some View {
    readyPlayer(detachesVideoLayer: viewModel.isFullScreenPresented)
  }

  private func readyPlayer(detachesVideoLayer: Bool) -> some View {
    let isPlaying: Bool
    if case .ready(let playing) = viewModel.playerPhase {
      isPlaying = playing
    } else {
      isPlaying = false
    }

    return ZStack(alignment: .topLeading) {
      // Video layer
      VideoPlayerLayerView(player: detachesVideoLayer ? nil : viewModel.player)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      // Thumbnail overlay (visible when not playing)
      if !isPlaying {
        KFImage(viewModel.video.thumbnailURL)
          .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
          .placeholder { ColorToken.brandBlackSprout.color }
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
      }

      // Gradient overlay
      LinearGradient(
        colors: [.clear, Color.black.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
      )

      // Tap area (재생 중일 때만 컨트롤 토글)
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          Task { await viewModel.send(.tapPlayerArea) }
        }

      subtitleOverlay(bottomPadding: viewModel.isControlsVisible ? 76 : 16)

      // Controls (재생 중엔 isControlsVisible에 따라 숨김)
      if viewModel.isControlsVisible {
        playerControls(isPlaying: isPlaying)
          .transition(.opacity)
      }

      // Seek 버퍼링 인디케이터
      if viewModel.isSeeking {
        ProgressView()
          .tint(ColorToken.grayScale30.color)
          .scaleEffect(1.3)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: viewModel.isControlsVisible)
  }

  private func playerControls(isPlaying: Bool) -> some View {
    playerControls(isPlaying: isPlaying, isFullScreen: false)
  }

  private func playerControls(isPlaying: Bool, isFullScreen: Bool) -> some View {
    ZStack(alignment: .topLeading) {
      // Top-right: subtitles + mute + fullscreen
      HStack(spacing: 10) {
        if viewModel.subtitles.isEmpty == false {
          Button {
            Task { await viewModel.send(.toggleSubtitles) }
          } label: {
            Image(systemName: viewModel.isSubtitlesEnabled ? "captions.bubble.fill" : "captions.bubble")
              .font(.system(size: 14))
              .foregroundStyle(ColorToken.grayScale30.color)
              .frame(width: 44, height: 44)
              .contentShape(Rectangle())
          }
          .disabled(viewModel.isSubtitleLoading)
        }

        Button {
          Task { await viewModel.send(.toggleMute) }
        } label: {
          Image(systemName: viewModel.isMuted ? "speaker.slash" : "speaker.wave.2")
            .font(.system(size: 14))
            .foregroundStyle(ColorToken.grayScale30.color)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }

        Button {
          Task {
            await viewModel.send(isFullScreen ? .exitFullScreen : .enterFullScreen)
          }
        } label: {
          Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
            .font(.system(size: 14))
            .foregroundStyle(ColorToken.grayScale30.color)
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
      }
      .padding([.top, .trailing], 14)
      .frame(maxWidth: .infinity, alignment: .trailing)

      // Center: play/pause
      Button {
        Task { await viewModel.send(.togglePlay) }
      } label: {
        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
          .font(.system(size: 22))
          .foregroundStyle(ColorToken.grayScale30.color)
          .frame(width: 64, height: 64)
          .background(Color.black.opacity(0.8))
          .clipShape(Circle())
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)

      // Bottom controls
      VStack(alignment: .leading, spacing: 4) {
        Spacer()

        // Current time
        Text(formatTime(viewModel.currentTime))
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(ColorToken.grayScale30.color)
          .padding(.leading, 16)

        // Duration
        HStack {
          Spacer()
          Text(formatTime(viewModel.duration))
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(ColorToken.grayScale30.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(.horizontal, 16)

        // Progress bar (bottom-most)
        Slider(
          value: $viewModel.currentTime,
          in: 0...max(viewModel.duration, 1),
          onEditingChanged: { editing in
            if !editing {
              Task { await viewModel.send(.seek(to: viewModel.currentTime)) }
            }
          }
        )
        .tint(ColorToken.grayScale30.color)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
      }
    }
  }

  private var fullScreenPlayer: some View {
    ZStack {
      Color.black.ignoresSafeArea()

      switch viewModel.playerPhase {
      case .loading:
        loadingPlayer
      case .error:
        errorPlayer
      case .ready:
        fullScreenReadyPlayer
      }
    }
    .statusBarHidden()
    .persistentSystemOverlays(.hidden)
    .gesture(
      DragGesture(minimumDistance: 40)
        .onEnded { value in
          if value.translation.height > 0 {
            Task { await viewModel.send(.exitFullScreen) }
          }
        }
    )
  }

  private var fullScreenReadyPlayer: some View {
    let isPlaying: Bool
    if case .ready(let playing) = viewModel.playerPhase {
      isPlaying = playing
    } else {
      isPlaying = false
    }

    return ZStack(alignment: .topLeading) {
      VideoPlayerLayerView(player: viewModel.player, videoGravity: .resizeAspect)
        .ignoresSafeArea()

      LinearGradient(
        colors: [Color.black.opacity(0.7), .clear, Color.black.opacity(0.75)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          Task { await viewModel.send(.tapPlayerArea) }
        }

      subtitleOverlay(bottomPadding: viewModel.isControlsVisible ? 92 : 28)

      if viewModel.isControlsVisible {
        playerControls(isPlaying: isPlaying, isFullScreen: true)
          .transition(.opacity)
      }

      if viewModel.isSeeking {
        ProgressView()
          .tint(ColorToken.grayScale30.color)
          .scaleEffect(1.3)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: viewModel.isControlsVisible)
  }

  // MARK: - Core Metadata

  private var coreMetadata: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(viewModel.video.title)
        .font(TypographyToken.pretendardTitle1.font)
        .foregroundStyle(ColorToken.grayScale30.color)
        .lineSpacing(4)

      HStack(spacing: 8) {
        Text("조회 \(viewModel.video.viewCount.formatted(.number))회")
        Text("·")
        Text(formattedDate(viewModel.video.createdAt))
        Text("·")
        Text("HLS · \(viewModel.selectedQuality)")
      }
      .font(TypographyToken.pretendardCaption1.font)
      .foregroundStyle(ColorToken.grayScale75.color)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Action Row

  private var actionRow: some View {
    HStack(spacing: 10) {
      Button {
        Task { await viewModel.send(.toggleLike) }
      } label: {
        HStack(spacing: 8) {
          Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
            .font(.system(size: 15))
            .foregroundStyle(viewModel.isLiked ? ColorToken.grayScale45.color : ColorToken.grayScale60.color)
          Text("좋아요 \(viewModel.likeCount.formatted(.number))")
            .font(TypographyToken.pretendardBody3.font)
            .foregroundStyle(viewModel.isLiked ? ColorToken.grayScale45.color : ColorToken.grayScale60.color)
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .frame(maxWidth: .infinity)
        .background(viewModel.isLiked ? ColorToken.mainAccent.color : ColorToken.brandBlackSprout.color)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
          if viewModel.isLiked {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(ColorToken.brandDeepSprout.color, lineWidth: 1)
          }
        }
      }

      Button {
        Task { await viewModel.send(.toggleSubtitles) }
      } label: {
        HStack(spacing: 8) {
          Image(systemName: viewModel.isSubtitlesEnabled ? "captions.bubble.fill" : "captions.bubble")
            .font(.system(size: 15))
            .foregroundStyle(subtitleActionForegroundColor)
          Text(subtitleActionTitle)
            .font(TypographyToken.pretendardBody3.font)
            .foregroundStyle(subtitleActionForegroundColor)
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .frame(maxWidth: .infinity)
        .background(subtitleActionBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
          if viewModel.isSubtitlesEnabled {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
              .strokeBorder(ColorToken.brandDeepSprout.color, lineWidth: 1)
          }
        }
      }
      .disabled(viewModel.subtitles.isEmpty || viewModel.isSubtitleLoading)
    }
  }

  private var subtitleActionTitle: String {
    if viewModel.subtitles.isEmpty {
      return "자막 없음"
    }
    if viewModel.isSubtitleLoading {
      return "자막 로딩"
    }
    return viewModel.isSubtitlesEnabled ? "자막 켬" : "자막 끔"
  }

  private var subtitleActionForegroundColor: Color {
    if viewModel.isSubtitlesEnabled {
      return ColorToken.grayScale45.color
    }
    return ColorToken.grayScale60.color
  }

  private var subtitleActionBackgroundColor: Color {
    if viewModel.isSubtitlesEnabled {
      return ColorToken.mainAccent.color
    }
    return ColorToken.brandBlackSprout.color
  }

  // MARK: - Expandable Description

  private var expandableDescription: some View {
    VStack(alignment: .leading, spacing: 8) {
      let desc = viewModel.video.description
      let isEmpty = desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

      Text(isEmpty ? "등록된 설명이 없습니다" : desc)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale60.color)
        .lineSpacing(4)
        .lineLimit(viewModel.isDescriptionExpanded ? nil : 3)
        .frame(maxWidth: .infinity, alignment: .leading)

      if !isEmpty {
        Button {
          Task { await viewModel.send(.toggleDescription) }
        } label: {
          Text(viewModel.isDescriptionExpanded ? "접기" : "더보기")
            .font(TypographyToken.pretendardBody3.font)
            .foregroundStyle(ColorToken.grayScale30.color)
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Self.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .strokeBorder(Self.cardStroke, lineWidth: 1)
    }
  }

  // MARK: - Quality Section

  @ViewBuilder
  private var subtitleSection: some View {
    if viewModel.subtitles.isEmpty == false {
      if viewModel.isSubtitleMenuVisible {
        subtitleMenu
      } else {
        subtitleSelectorRow
      }
    }
  }

  private var subtitleSelectorRow: some View {
    let canChange = viewModel.subtitles.count > 1
    let selectedName = viewModel.subtitles.first { $0.language == viewModel.selectedSubtitleLanguage }?.name
      ?? "자막"

    return HStack(spacing: 10) {
      Button {
        Task { await viewModel.send(.toggleSubtitles) }
      } label: {
        Image(systemName: viewModel.isSubtitlesEnabled ? "captions.bubble.fill" : "captions.bubble")
          .font(.system(size: 15))
          .foregroundStyle(viewModel.isSubtitlesEnabled ? ColorToken.grayScale45.color : ColorToken.grayScale60.color)
          .frame(width: 44, height: 44)
          .background(viewModel.isSubtitlesEnabled ? ColorToken.mainAccent.color : ColorToken.brandBlackSprout.color)
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
      .disabled(viewModel.isSubtitleLoading)

      Button {
        guard canChange else { return }
        Task { await viewModel.send(.toggleSubtitleMenu) }
      } label: {
        HStack {
          Text(viewModel.isSubtitleLoading ? "자막 불러오는 중" : selectedName)
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale60.color)

          Spacer()

          if canChange {
            Image(systemName: "chevron.right")
              .font(.system(size: 13))
              .foregroundStyle(ColorToken.grayScale75.color)
          }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(Self.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(Self.cardStroke, lineWidth: 1)
        }
      }
      .disabled(!canChange)
    }
  }

  private var subtitleMenu: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("자막 선택")
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.grayScale30.color)

      ForEach(viewModel.subtitles, id: \.language) { subtitle in
        let isSelected = subtitle.language == viewModel.selectedSubtitleLanguage

        Button {
          Task { await viewModel.send(.selectSubtitle(subtitle.language)) }
        } label: {
          HStack {
            Text(subtitle.name)
              .font(TypographyToken.pretendardBody2.font)
              .foregroundStyle(isSelected ? ColorToken.grayScale45.color : ColorToken.grayScale60.color)
            Spacer()
            if isSelected {
              Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ColorToken.grayScale45.color)
            }
          }
          .padding(.horizontal, 12)
          .frame(height: 36)
          .frame(maxWidth: .infinity)
          .background(isSelected ? ColorToken.mainAccent.color : ColorToken.brandBlackSprout.color)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Self.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .strokeBorder(Self.cardStroke, lineWidth: 1)
    }
  }

  @ViewBuilder
  private var qualitySection: some View {
    if viewModel.isQualityMenuVisible {
      qualityMenu
    } else {
      qualitySelectorRow
    }
  }

  private var qualitySelectorRow: some View {
    let canChange = viewModel.qualities.count > 1

    return Button {
      guard canChange else { return }
      Task { await viewModel.send(.toggleQualityMenu) }
    } label: {
      HStack {
        HStack(spacing: 8) {
          Image(systemName: "slider.horizontal.3")
            .font(.system(size: 15))
            .foregroundStyle(ColorToken.grayScale60.color)
          Text("화질")
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale60.color)
        }

        Spacer()

        if canChange {
          HStack(spacing: 4) {
            Text("\(viewModel.selectedQuality) 변경")
              .font(TypographyToken.pretendardBody3.font)
              .foregroundStyle(ColorToken.grayScale75.color)
            Image(systemName: "chevron.right")
              .font(.system(size: 13))
              .foregroundStyle(ColorToken.grayScale75.color)
          }
        } else {
          Text(viewModel.selectedQuality)
            .font(TypographyToken.pretendardBody3.font)
            .foregroundStyle(ColorToken.grayScale75.color)
        }
      }
      .padding(.horizontal, 14)
      .frame(height: 48)
      .frame(maxWidth: .infinity)
      .background(Self.cardBackground)
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .strokeBorder(Self.cardStroke, lineWidth: 1)
      }
    }
    .disabled(!canChange)
  }

  private var qualityMenu: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("화질 선택")
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.grayScale30.color)

      ForEach(viewModel.qualities) { quality in
        let isSelected = quality.label == viewModel.selectedQuality

        Button {
          Task { await viewModel.send(.selectQuality(quality.label)) }
        } label: {
          HStack {
            Text(quality.label)
              .font(TypographyToken.pretendardBody2.font)
              .foregroundStyle(isSelected ? ColorToken.grayScale45.color : ColorToken.grayScale60.color)
            Spacer()
            if isSelected {
              Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ColorToken.grayScale45.color)
            }
          }
          .padding(.horizontal, 12)
          .frame(height: 36)
          .frame(maxWidth: .infinity)
          .background(isSelected ? ColorToken.mainAccent.color : ColorToken.brandBlackSprout.color)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Self.cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .strokeBorder(Self.cardStroke, lineWidth: 1)
    }
  }

  // MARK: - Helpers

  private func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let totalSeconds = Int(seconds)
    let minutes = totalSeconds / 60
    let secs = totalSeconds % 60
    return String(format: "%d:%02d", minutes, secs)
  }

  private func formattedDate(_ isoString: String) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let date = formatter.date(from: isoString) else { return isoString }
    let display = DateFormatter()
    display.dateFormat = "yyyy.MM.dd"
    return display.string(from: date)
  }

  @ViewBuilder
  private func subtitleOverlay(bottomPadding: CGFloat) -> some View {
    if let text = viewModel.currentSubtitleText {
      VStack {
        Spacer()
        SubtitleOverlayView(text: text)
          .padding(.horizontal, 18)
          .padding(.bottom, bottomPadding)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .allowsHitTesting(false)
    }
  }

  @MainActor
  private func requestOrientation(_ orientation: UIInterfaceOrientationMask) {
    AppOrientationLock.supportedOrientations = orientation
    guard
      let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first(where: { $0.activationState == .foregroundActive })
    else { return }
    scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
  }
}
