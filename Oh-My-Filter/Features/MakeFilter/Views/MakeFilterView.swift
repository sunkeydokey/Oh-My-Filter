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

        inputSection(
          title: "필터명",
          placeholder: "필터 이름을 입력해주세요.",
          text: Binding(
            get: { viewModel.state.name },
            set: { viewModel.send(.nameChanged($0)) }
          )
        )

        categorySection
        representativeImageSection

        inputSection(
          title: "필터 소개",
          placeholder: "이 필터에 대해 간단하게 소개해주세요.",
          text: Binding(
            get: { viewModel.state.introduction },
            set: { viewModel.send(.introductionChanged($0)) }
          )
        )

        priceSection

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
      submitButton
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
      .presentationDetents([.medium, .large])
      .presentationBackground(ColorToken.brandBlackSprout.color)
    }
  }

  private var submitButton: some View {
    Button {
      viewModel.send(.submitTapped)
    } label: {
      HStack(spacing: 8) {
        if viewModel.state.isSubmitting {
          ProgressView()
            .tint(ColorToken.grayScale0.color)
        }

        Text(viewModel.state.submitButtonTitle)
          .font(TypographyToken.pretendardBody2.font)
          .bold()
      }
      .foregroundStyle(ColorToken.grayScale0.color)
      .frame(maxWidth: .infinity)
      .frame(height: 52)
      .background(submitButtonBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .padding(.horizontal, 20)
      .padding(.top, 12)
      .padding(.bottom, 8)
      .background(ColorToken.brandBlackSprout.color)
    }
    .buttonStyle(.plain)
    .disabled(viewModel.state.canSubmit == false)
  }

  private var submitButtonBackground: Color {
    viewModel.state.canSubmit
      ? ColorToken.sesacFilterDeepTurquoise.color
      : ColorToken.grayScale90.color
  }

  private func inputSection(
    title: String,
    placeholder: String,
    text: Binding<String>
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      sectionTitle(title)

      TextField(placeholder, text: text)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .tint(ColorToken.mainAccent.color)
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .stroke(ColorToken.brandDeepSprout.color, lineWidth: 2)
        }
    }
  }

  private var categorySection: some View {
    VStack(alignment: .leading, spacing: 10) {
      sectionTitle("카테고리")

      ScrollView(.horizontal) {
        HStack(spacing: 8) {
          ForEach(FilterMakeCategory.allCases, id: \.self) { category in
            Button {
              viewModel.send(.categorySelected(category))
            } label: {
              Text(category.rawValue)
                .font(TypographyToken.pretendardBody3.font)
                .fontWeight(viewModel.state.category == category ? .bold : .medium)
                .foregroundStyle(viewModel.state.category == category ? ColorToken.grayScale15.color : ColorToken.grayScale60.color)
                .padding(.horizontal, 17)
                .frame(height: 28)
                .background(
                  viewModel.state.category == category ? ColorToken.sesacFilterDeepTurquoise.color : ColorToken.brandDeepSprout.color,
                  in: Capsule()
                )
                .buttonHitArea(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }

  private var representativeImageSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        sectionTitle("대표 사진 등록")

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

  private var priceSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      sectionTitle("판매 가격")

      HStack {
        TextField(
          "1,000",
          text: Binding(
            get: { viewModel.state.priceInput },
            set: { viewModel.send(.priceChanged($0)) }
          )
        )
        .keyboardType(.numberPad)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .tint(ColorToken.mainAccent.color)

        Text("원")
          .font(TypographyToken.pretendardBody3.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale60.color)
      }
      .padding(.horizontal, 12)
      .frame(height: 42)
      .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .stroke(ColorToken.brandDeepSprout.color, lineWidth: 2)
      }
    }
  }

  private func sectionTitle(_ title: String) -> some View {
    Text(title)
      .font(TypographyToken.mulgyeolCaption1.font)
      .foregroundStyle(ColorToken.grayScale45.color)
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
