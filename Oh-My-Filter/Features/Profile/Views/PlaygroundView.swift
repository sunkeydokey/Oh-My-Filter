import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct PlaygroundView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel: PlaygroundViewModel
  @State private var pickerItems: [PhotosPickerItem] = []

  init(filter: OrderHistoryFilter) {
    _viewModel = State(initialValue: PlaygroundViewModel(filterID: filter.id))
  }

  var body: some View {
    VStack(spacing: 18) {
      CustomStackNavigationHeader(title: viewModel.state.filterTitle, onBack: { dismiss() }) {
        Color.clear
      }
      .padding(.horizontal, 20)

      content
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .padding(.top, 18)
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .swipeBackEnabled()
    .task {
      await viewModel.send(.task)
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
        phase: viewModel.state.applyPhase,
        boastPreloadedImages: currentBoastPreloadedMedia,
        onSaveCurrent: { Task { await viewModel.send(.saveCurrent) } },
        onSaveAll: { Task { await viewModel.send(.saveAll) } },
        onDismiss: { Task { await viewModel.send(.dismissApplySheet) } },
        onIndexChanged: { index in Task { await viewModel.send(.previewIndexChanged(index)) } }
      )
      .presentationDetents([.large])
      .presentationDragIndicator(.visible)
    }
  }

  @ViewBuilder
  private var content: some View {
    switch viewModel.state.phase {
    case .idle, .loading:
      ProgressView()
        .tint(ColorToken.mainAccent.color)
    case .loaded:
      VStack(spacing: 16) {
        Image(systemName: "camera.filters")
          .font(.system(size: 42, weight: .semibold))
          .foregroundStyle(ColorToken.mainAccent.color)

        Text("갤러리에서 사진이나 동영상을 선택해 필터를 적용해보세요.")
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 28)

        Button {
          Task { await viewModel.send(.tapApply) }
        } label: {
          Label("갤러리에서 선택", systemImage: "photo.on.rectangle")
            .font(TypographyToken.pretendardBody1.font.weight(.heavy))
            .foregroundStyle(ColorToken.grayScale100.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(ColorToken.mainAccent.color, in: .rect(cornerRadius: 8, style: .continuous))
            .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
      }
    case let .failed(message):
      VStack(spacing: 12) {
        Text(message)
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale60.color)
        Button("다시 시도") {
          Task { await viewModel.send(.retry) }
        }
        .font(TypographyToken.pretendardBody2.font.weight(.bold))
        .foregroundStyle(ColorToken.mainAccent.color)
      }
    }
  }

  private var isPicking: Binding<Bool> {
    Binding {
      viewModel.state.applyPhase == .picking
    } set: { isPresented in
      if !isPresented && viewModel.state.applyPhase == .picking {
        Task { await viewModel.send(.dismissApplySheet) }
      }
    }
  }

  private var isApplySheetPresented: Binding<Bool> {
    Binding {
      switch viewModel.state.applyPhase {
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

  private var currentBoastPreloadedMedia: [PhotoPickerUploadSelection] {
    guard case let .readyToSave(outputs, _) = viewModel.state.applyPhase else { return [] }
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
}
