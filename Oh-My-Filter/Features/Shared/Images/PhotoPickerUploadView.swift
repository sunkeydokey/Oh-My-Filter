import PhotosUI
import SwiftUI

struct PhotoPickerUploadView: View {
  let preset: ImageUploadPreset
  @Binding var selections: [PhotoPickerUploadSelection]

  @State private var pickerItems: [PhotosPickerItem] = []
  @State private var statusMessage: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        PhotosPicker(
          selection: $pickerItems,
          maxSelectionCount: preset.maxCount,
          matching: .images
        ) {
          Label("이미지", systemImage: "photo")
            .font(TypographyToken.pretendardCaption1.font.weight(.semibold))
            .foregroundStyle(ColorToken.brandBlackSprout.color)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(ColorToken.sesacFilterBrightTurquoise.color, in: .rect(cornerRadius: 8))
        }

        Text("\(selections.count)/\(preset.maxCount)")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)

        Spacer()
      }

      if selections.isEmpty == false {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(Array(selections.enumerated()), id: \.element.id) { index, selection in
              selectedImageChip(index: index, selection: selection)
            }
          }
        }
      }

      if let statusMessage {
        Text(statusMessage)
          .font(TypographyToken.pretendardCaption2.font)
          .foregroundStyle(ColorToken.sesacFilterBrightTurquoise.color)
      }
    }
    .onChange(of: pickerItems) { _, newItems in
      Task {
        await loadSelections(from: newItems)
      }
    }
  }

  private func selectedImageChip(
    index: Int,
    selection: PhotoPickerUploadSelection
  ) -> some View {
    HStack(spacing: 6) {
      Image(systemName: "photo")
        .font(.system(size: 13, weight: .semibold))

      Text("\(index + 1)")
        .font(TypographyToken.pretendardCaption1.font.weight(.semibold))
        .lineLimit(1)

      Button {
        selections.removeAll { $0.id == selection.id }
        pickerItems = Array(pickerItems.prefix(selections.count))
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 11, weight: .bold))
      }
      .buttonStyle(.plain)
    }
    .foregroundStyle(ColorToken.grayScale0.color)
    .padding(.horizontal, 10)
    .frame(height: 32)
    .background(ColorToken.grayScale90.color, in: .rect(cornerRadius: 8))
  }

  @MainActor
  private func loadSelections(from items: [PhotosPickerItem]) async {
    let limitedItems = Array(items.prefix(preset.maxCount))
    statusMessage = items.count > preset.maxCount ? preset.maximumSelectionMessage : nil

    var loadedSelections: [PhotoPickerUploadSelection] = []
    for (index, item) in limitedItems.enumerated() {
      guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
      loadedSelections.append(PhotoPickerUploadSelection(
        data: data,
        fileName: "image-\(index + 1).jpg"
      ))
    }

    selections = loadedSelections
    if pickerItems.count != limitedItems.count {
      pickerItems = limitedItems
    }
  }
}
