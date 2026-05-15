import CoreGraphics
import ImageIO
import Photos
import PhotosUI
import SwiftUI

struct MakeFilterView: View {
  @State private var viewModel: FilterMakeViewModel
  @State private var pickerItem: PhotosPickerItem?
  @Environment(\.dismiss) private var dismiss
  private let onSubmitSucceeded: (FilterDetail) -> Void

  init(
    mode: FilterMakeMode = .create,
    draft: FilterMakeDraft? = nil,
    onSubmitSucceeded: @escaping (FilterDetail) -> Void = { _ in }
  ) {
    _viewModel = State(initialValue: FilterMakeViewModel(mode: mode, draft: draft))
    self.onSubmitSucceeded = onSubmitSucceeded
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        CustomStackNavigationHeader(title: "MAKE", onBack: { dismiss() }) {
          Color.clear
        }

        MakeFilterTextInputSection(
          title: "필터명",
          placeholder: "필터 이름을 입력해주세요.",
          text: Binding(
            get: { viewModel.state.name },
            set: { viewModel.send(.nameChanged($0)) }
          )
        )

        MakeFilterCategorySection(
          selectedCategory: viewModel.state.category,
          onCategorySelected: { category in
            viewModel.send(.categorySelected(category))
          }
        )
        representativeImageSection

        MakeFilterTextInputSection(
          title: "필터 소개",
          placeholder: "이 필터에 대해 간단하게 소개해주세요.",
          text: Binding(
            get: { viewModel.state.introduction },
            set: { viewModel.send(.introductionChanged($0)) }
          )
        )

        MakeFilterPriceSection(
          priceInput: Binding(
            get: { viewModel.state.priceInput },
            set: { viewModel.send(.priceChanged($0)) }
          )
        )

        if let message = viewModel.state.submissionMessage {
          Text(message)
            .font(TypographyToken.pretendardCaption1.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .frame(maxWidth: .infinity, alignment: .center)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 24)
    }
    .scrollIndicators(.hidden)
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .swipeBackEnabled()
    .safeAreaInset(edge: .bottom) {
      MakeFilterSubmitButton(
        title: viewModel.state.submitButtonTitle,
        canSubmit: viewModel.state.canSubmit,
        isSubmitting: viewModel.state.isSubmitting,
        onSubmit: {
          viewModel.send(.submitTapped)
        }
      )
    }
    .task(id: pickerItem) {
      await loadRepresentativeImage()
    }
    .onChange(of: viewModel.state.route) { _, route in
      guard case let .created(detail)? = route else { return }
      onSubmitSucceeded(detail)
      viewModel.send(.routeHandled)
    }
    .sheet(
      isPresented: Binding(
        get: { viewModel.state.animeConversionState != .idle },
        set: { isPresented in
          if !isPresented { viewModel.send(.animeConversionDismissed) }
        }
      )
    ) {
      AnimeConversionPreviewSheet(
        state: viewModel.state.animeConversionState,
        onChoiceMade: { useConverted in
          viewModel.send(.animeConversionChoiceMade(useConverted: useConverted))
        },
        onDismiss: {
          viewModel.send(.animeConversionDismissed)
        }
      )
      .presentationDetents([.large])
      .presentationBackground(ColorToken.brandBlackSprout.color)
    }
  }

  private var representativeImageSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        MakeFilterSectionTitle("대표 사진 등록")

        Spacer()

        if viewModel.state.hasRepresentativeImage {
          PhotosPicker(selection: $pickerItem, matching: .images) {
            Image(systemName: "photo.badge.plus")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(ColorToken.grayScale60.color)
          }
          .accessibilityLabel("대표 사진 변경")

          NavigationLink {
            FilterEditView(
              draft: viewModel.state.draft,
              filterParameterValues: Binding(
                get: { viewModel.state.filterParameterValues },
                set: { viewModel.send(.filterParameterValuesChanged($0)) }
              )
            )
          } label: {
            Text("수정하기")
              .font(TypographyToken.pretendardBody3.font)
              .foregroundStyle(ColorToken.grayScale60.color)
          }

          Button {
            viewModel.send(.animeConvertTapped)
          } label: {
            Text("변환하기")
              .font(TypographyToken.pretendardBody3.font)
              .foregroundStyle(
                viewModel.state.animeConversionState == .converting
                  ? ColorToken.sesacFilterDeepTurquoise.color.opacity(0.4)
                  : ColorToken.sesacFilterDeepTurquoise.color
              )
          }
          .disabled(viewModel.state.animeConversionState == .converting)
        }
      }

      if let image = viewModel.state.representativePreviewImage {
        representativePreview(image: image)

        FilterDetailMetadataView(
          title: viewModel.state.photoMetadata.headerValue,
          trailing: "EXIF",
          rows: viewModel.state.photoMetadata.displayRows,
          isCompact: true
        )

        FilterDetailValuesView(values: viewModel.state.filterValues, isLocked: false)
      } else {
        PhotosPicker(selection: $pickerItem, matching: .images) {
          VStack(spacing: 10) {
            Image(systemName: "photo.badge.plus")
              .font(.system(size: 28, weight: .semibold))
            Text("대표 사진을 선택해주세요.")
              .font(TypographyToken.pretendardBody3.font)
              .fontWeight(.medium)
          }
          .foregroundStyle(ColorToken.grayScale60.color)
          .frame(maxWidth: .infinity)
          .frame(height: 112)
          .background(ColorToken.brandDeepSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
              .stroke(ColorToken.grayScale90.color, lineWidth: 1)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func representativePreview(image: CGImage) -> some View {
    Group {
      if let comparisonPreviewState = viewModel.state.comparisonPreviewState {
        FilterImageComparisonView(previewState: comparisonPreviewState)
          .padding(.bottom, 8)
      } else {
        Image(decorative: image, scale: 1)
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity)
          .aspectRatio(1, contentMode: .fit)
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
              .stroke(ColorToken.brandDeepSprout.color, lineWidth: 2)
          }
          .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .padding(.bottom, 8)
      }
    }
  }

  @MainActor
  private func loadRepresentativeImage() async {
    guard let pickerItem else { return }
    defer { self.pickerItem = nil }

    guard let data = try? await pickerItem.loadTransferable(type: Data.self) else { return }

    let assetIdentifier = pickerItem.itemIdentifier
    let metadata = await Task.detached(priority: .userInitiated) {
      metadataFromOriginalAsset(identifier: assetIdentifier)
    }.value

    let info = await LiveFilterMakeImageInfoReader().selectedImageInfo(from: data, overridingMetadata: metadata)
    viewModel.send(.representativeImageInfoChanged(info))
  }
}

private func metadataFromOriginalAsset(identifier: String?) -> FilterDetailMetadata? {
  guard
    let identifier,
    let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
  else { return nil }

  var result: FilterDetailMetadata?
  let options = PHImageRequestOptions()
  options.version = .original
  options.isNetworkAccessAllowed = true
  options.isSynchronous = true

  PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
    guard
      let data,
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [AnyHashable: Any]
    else { return }
    result = LiveFilterMakeImageInfoReader().metadata(from: properties)
  }

  return result
}
