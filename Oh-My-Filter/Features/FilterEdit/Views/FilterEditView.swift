import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct FilterEditView: View {
  @State private var viewModel: FilterEditViewModel
  @Binding private var filterParameterValues: [FilterEditParameter: Double]
  let onFilterParameterValuesChange: ([FilterEditParameter: Double]) -> Void

  init(
    draft: FilterMakeDraft,
    filterParameterValues: Binding<[FilterEditParameter: Double]>? = nil,
    onFilterParameterValuesChange: @escaping ([FilterEditParameter: Double]) -> Void = { _ in }
  ) {
    let filterParameterValues = filterParameterValues ?? .constant(draft.filterParameterValues)
    _filterParameterValues = filterParameterValues
    _viewModel = State(initialValue: FilterEditViewModel(
      draft: draft,
      filterParameterValues: filterParameterValues.wrappedValue
    ))
    self.onFilterParameterValuesChange = onFilterParameterValuesChange
  }

  var body: some View {
    VStack(spacing: 0) {
      preview

      editControls
    }
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
    .mulgyeolNavigationTitle("EDIT")
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
        } label: {
          Image(systemName: "square.split.2x1")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(ColorToken.grayScale45.color)
            .frame(width: 40, height: 40)
            .background(ColorToken.grayScale90.color.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .accessibilityLabel("비교")
      }
    }
    .onChange(of: filterParameterValues) { _, values in
      viewModel.renderPreview(with: values)
    }
  }

  private var preview: some View {
    ZStack {
      if let image = viewModel.state.previewImage {
        Image(decorative: image, scale: 1)
          .resizable()
          .scaledToFill()
      } else if let image = viewModel.state.draft.representativeImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        FilterImagePlaceholderView()
      }
    }
    .frame(maxWidth: .infinity)
    .frame(maxHeight: .infinity)
    .clipped()
    .layoutPriority(1)
    .overlay(alignment: .bottomLeading) {
      VStack(alignment: .leading, spacing: 6) {
        Text(viewModel.state.draft.name.isEmpty ? "Untitled Filter" : viewModel.state.draft.name)
          .font(TypographyToken.pretendardBody1.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale0.color)
          .lineLimit(1)

        Text(viewModel.state.draft.category.rawValue)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)
      }
      .padding(20)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        LinearGradient(
          colors: [.clear, ColorToken.brandBlackSprout.color.opacity(0.78)],
          startPoint: .top,
          endPoint: .bottom
        )
      )
    }
  }

  private var editControls: some View {
    VStack(spacing: 16) {
      HStack {
        HStack(spacing: 8) {
          editIconButton(.undo) {
            sendAndSync(.undo)
          }

          editIconButton(.redo) {
            sendAndSync(.redo)
          }
        }

        Spacer()

        editIconButton(.controls) {
          sendAndSync(.reset)
        }
      }
      .padding(.horizontal, 20)
      .padding(.top, 16)

      HStack(spacing: 12) {
        let selectedParameter = viewModel.state.selectedParameter

        Slider(
          value: Binding(
            get: { selectedValue },
            set: { sendAndSync(.valueChanged($0)) }
          ),
          in: selectedParameter.range,
          step: selectedParameter.step,
          onEditingChanged: { isEditing in
            _ = viewModel.send(isEditing ? .valueEditingStarted : .valueEditingEnded, values: filterParameterValues)
          }
        )
        .tint(ColorToken.sesacFilterBrightTurquoise.color)

        Text(selectedParameter.displayText(for: selectedValue))
          .font(TypographyToken.pretendardBody3.font)
          .bold()
          .monospacedDigit()
          .foregroundStyle(ColorToken.grayScale0.color)
          .lineLimit(1)
          .padding(.horizontal, 8)
          .frame(minWidth: 52, minHeight: 28)
          .background(ColorToken.brandDeepSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
          .layoutPriority(1)
      }
      .padding(.horizontal, 20)
      .frame(maxWidth: .infinity)

      VStack(spacing: 8) {
        HStack {
          Text(viewModel.state.selectedParameter.rangeLabelMin)

          Spacer()

          Text(viewModel.state.selectedParameter.rangeLabelMax)
        }
        .font(TypographyToken.pretendardCaption2.font)
        .foregroundStyle(ColorToken.grayScale60.color)
        .monospacedDigit()

        Text(viewModel.state.selectedParameter.descriptionText)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .lineLimit(2)
          .multilineTextAlignment(.center)
      }
      .padding(.horizontal, 20)
      .frame(maxWidth: .infinity)

      ScrollView(.horizontal) {
        LazyHStack(spacing: 12) {
          ForEach(FilterEditParameter.allCases, id: \.self) { parameter in
            parameterButton(parameter)
          }
        }
        .padding(.bottom, 16)
      }
      .scrollIndicators(.hidden)
      .contentMargins(.horizontal, 20, for: .scrollContent)
      .frame(maxWidth: .infinity)
    }
    .frame(maxWidth: .infinity)
    .containerRelativeFrame(.horizontal)
    .background(ColorToken.brandBlackSprout.color)
    .fixedSize(horizontal: false, vertical: true)
  }

  private func editIconButton(
    _ icon: IconToken,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: icon.symbolName)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(ColorToken.grayScale45.color)
        .frame(width: 40, height: 32)
        .background(ColorToken.grayScale90.color.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    .buttonStyle(.plain)
  }

  private func sendAndSync(_ action: FilterEditAction) {
    let updatedValues = viewModel.send(action, values: filterParameterValues)
    filterParameterValues = updatedValues
    onFilterParameterValuesChange(updatedValues)
  }

  private var selectedValue: Double {
    let parameter = viewModel.state.selectedParameter
    return filterParameterValues[parameter, default: parameter.defaultValue]
  }

  private func parameterButton(_ parameter: FilterEditParameter) -> some View {
    let isSelected = viewModel.state.selectedParameter == parameter

    return Button {
      _ = viewModel.send(.parameterSelected(parameter), values: filterParameterValues)
    } label: {
      VStack(spacing: 8) {
        Image(systemName: parameter.icon.symbolName)
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(isSelected ? ColorToken.grayScale0.color : ColorToken.grayScale60.color)
          .frame(width: 32, height: 32)

        Text(parameter.label)
          .font(TypographyToken.pretendardCaption2.font)
          .fontWeight(.semibold)
          .foregroundStyle(isSelected ? ColorToken.grayScale0.color : ColorToken.grayScale60.color)
          .lineLimit(1)
          .minimumScaleFactor(0.65)
      }
      .frame(width: 76)
    }
    .buttonStyle(.plain)
  }
}

#if canImport(UIKit)
private extension FilterMakeDraft {
  var representativeImage: UIImage? {
    guard let representativeImageData else { return nil }
    return UIImage(data: representativeImageData)
  }
}
#endif
