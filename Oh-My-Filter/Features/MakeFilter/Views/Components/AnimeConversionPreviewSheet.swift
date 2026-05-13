import CoreGraphics
import SwiftUI

struct AnimeConversionPreviewSheet: View {
  let state: AnimeConversionState
  let onChoiceMade: (Bool) -> Void
  let onDismiss: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      switch state {
      case .idle:
        EmptyView()

      case .converting:
        convertingView

      case let .awaitingChoice(result):
        choiceView(result: result)

      case let .failed(message):
        failedView(message: message)
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.horizontal, 20)
  }

  private var convertingView: some View {
    VStack(spacing: 16) {
      ProgressView()
        .tint(ColorToken.mainAccent.color)
        .scaleEffect(1.4)
      Text("애니 변환 중...")
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale45.color)

      Button(action: onDismiss) {
        Text("취소")
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(ColorToken.brandDeepSprout.color, in: RoundedRectangle(cornerRadius: 8))
          .buttonHitArea(RoundedRectangle(cornerRadius: 8))
      }
    }
  }

  private func choiceView(result: AnimeConversionResult) -> some View {
    VStack(spacing: 20) {
      HStack(spacing: 12) {
        imagePreviewCard(image: result.originalPreview, label: "원본")
        imagePreviewCard(image: result.convertedPreview, label: "변환본")
      }

      VStack(spacing: 12) {
        Button {
          onChoiceMade(true)
        } label: {
          Text("변환본 사용")
            .font(TypographyToken.pretendardBody1.font)
            .bold()
            .foregroundStyle(ColorToken.grayScale60.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ColorToken.mainAccent.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }

        Button {
          onChoiceMade(false)
        } label: {
          Text("원본 유지")
            .font(TypographyToken.pretendardBody1.font)
            .bold()
            .foregroundStyle(ColorToken.mainAccent.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ColorToken.mainAccent.color, lineWidth: 1.5)
            )
            .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
      }
    }
  }

  private func imagePreviewCard(image: CGImage, label: String) -> some View {
    VStack(spacing: 8) {
      Image(decorative: image, scale: 1)
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(ColorToken.brandDeepSprout.color, lineWidth: 1.5)
        }

      Text(label)
        .font(TypographyToken.pretendardCaption1.font)
        .foregroundStyle(ColorToken.grayScale45.color)
    }
  }

  private func failedView(message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 48))
        .foregroundStyle(ColorToken.grayScale45.color)

      Text(message)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale45.color)
        .multilineTextAlignment(.center)

      Button(action: onDismiss) {
        Text("닫기")
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(ColorToken.brandDeepSprout.color, in: RoundedRectangle(cornerRadius: 8))
          .buttonHitArea(RoundedRectangle(cornerRadius: 8))
      }
    }
  }
}
