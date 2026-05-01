import PhotosUI
import SwiftUI

struct PhotoPickerUploadView: View {
  let preset: ImageUploadPreset
  @Binding var selections: [PhotoPickerUploadSelection]

  @State private var pickerItems: [PhotosPickerItem] = []
  @State private var pickedImages: [PickedImage] = []
  @State private var loadGeneration = 0
  @State private var statusMessage: String?

  private var displayedSelections: [PhotoPickerUploadSelection] {
    pickedImages.map(\.selection)
  }

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

        Text("\(displayedSelections.count)/\(preset.maxCount)")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)

        Spacer()
      }

      if displayedSelections.isEmpty == false {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(Array(displayedSelections.enumerated()), id: \.element.id) { index, selection in
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
    .onChange(of: selections) { _, newSelections in
      guard newSelections.isEmpty else { return }
      resetPickedImages()
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
        removeSelection(id: selection.id)
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

  private func removeSelection(id: PhotoPickerUploadSelection.ID) {
    pickedImages.removeAll { $0.selection.id == id }
    pickerItems = pickedImages.map(\.item)
    selections = displayedSelections
    statusMessage = nil
  }

  private func resetPickedImages() {
    loadGeneration += 1
    pickedImages = []
    pickerItems = []
    statusMessage = nil
  }

  @MainActor
  private func loadSelections(from items: [PhotosPickerItem]) async {
    loadGeneration += 1
    let generation = loadGeneration
    let limitedItems = Array(items.prefix(preset.maxCount))
    statusMessage = items.count > preset.maxCount ? preset.maximumSelectionMessage : nil

    var loadedImages: [PickedImage] = []
    for (index, item) in limitedItems.enumerated() {
      if let pickedImage = pickedImages.first(where: { $0.item == item }) {
        loadedImages.append(pickedImage)
        continue
      }

      guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
      guard generation == loadGeneration else { return }
      loadedImages.append(PickedImage(
        item: item,
        selection: PhotoPickerUploadSelection(
          data: data,
          fileName: "image-\(index + 1).jpg"
        )
      ))
    }

    guard generation == loadGeneration else { return }
    pickedImages = loadedImages
    selections = displayedSelections
    if pickerItems.count != limitedItems.count {
      pickerItems = limitedItems
    }
  }
}

private struct PickedImage: Identifiable {
  let item: PhotosPickerItem
  let selection: PhotoPickerUploadSelection

  var id: PhotoPickerUploadSelection.ID {
    selection.id
  }
}
