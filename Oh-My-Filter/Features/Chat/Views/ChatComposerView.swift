import SwiftUI

struct ChatComposerView: View {
  let selectedImages: [PhotoPickerUploadSelection]
  let imageSelectionMessage: String?
  let composerText: String
  let canSend: Bool
  var isFocused: FocusState<Bool>.Binding
  let onImageSelectionChanged: ([PhotoPickerUploadSelection]) -> Void
  let onComposerChanged: (String) -> Void
  let onSend: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      PhotoPickerUploadView(
        preset: .chat,
        selections: Binding(
          get: { selectedImages },
          set: onImageSelectionChanged
        )
      )

      if let imageSelectionMessage {
        Text(imageSelectionMessage)
          .font(TypographyToken.pretendardCaption2.font)
          .foregroundStyle(ColorToken.mainAccent.color)
      }

      HStack(alignment: .bottom, spacing: 12) {
        TextField("메시지를 입력하세요...", text: Binding(
          get: { composerText },
          set: onComposerChanged
        ), axis: .vertical)
        .lineLimit(1...3)
        .focused(isFocused)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()

        Button(action: onSend) {
          Image(systemName: "arrow.up")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(ColorToken.brandBlackSprout.color)
            .frame(width: 40, height: 40)
            .background(
              canSend ? ColorToken.mainAccent.color : ColorToken.grayScale75.color,
              in: .rect(cornerRadius: 20)
            )
        }
        .disabled(canSend == false)
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
}
