import CoreGraphics
import SwiftUI

struct FilterApplyProgressSheet: View {
  let phase: ApplyPhotoPhase
  let boastPreloadedImages: [PhotoPickerUploadSelection]
  let onSaveCurrent: () -> Void
  let onSaveAll: () -> Void
  let onDismiss: () -> Void
  let onIndexChanged: (Int) -> Void

  @State private var showBoastSheet = false

  var body: some View {
    VStack(spacing: 24) {
      Spacer()

      switch phase {
      case let .rendering(progress, total):
        ProgressView(value: Double(progress + 1), total: Double(max(total, 1)))
          .tint(ColorToken.mainAccent.color)
          .padding(.horizontal, 40)
        Text(total > 1 ? "\(progress + 1) / \(total) 처리 중..." : "필터 적용 중...")
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale45.color)

      case let .saving(progress, total):
        if total > 1 {
          ProgressView(value: Double(progress), total: Double(total))
            .tint(ColorToken.mainAccent.color)
            .padding(.horizontal, 40)
          Text("\(progress) / \(total) 저장 중...")
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale45.color)
        } else {
          ProgressView()
            .tint(ColorToken.mainAccent.color)
            .scaleEffect(1.4)
          Text("사진 저장 중...")
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale45.color)
        }

      case let .readyToSave(images, currentIndex):
        TabView(selection: Binding(
          get: { currentIndex },
          set: { onIndexChanged($0) }
        )) {
          ForEach(Array(images.enumerated()), id: \.offset) { index, cgImage in
            Image(decorative: cgImage, scale: 1)
              .resizable()
              .scaledToFit()
              .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
              .padding(.horizontal, 20)
              .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: images.count > 1 ? .automatic : .never))
        .frame(height: 300)

        if images.count > 1 {
          Text("\(currentIndex + 1) / \(images.count)")
            .font(TypographyToken.pretendardCaption2.font)
            .foregroundStyle(ColorToken.grayScale45.color)
        }

        Text("필터가 적용된 사진을 저장하시겠어요?")
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .multilineTextAlignment(.center)

        VStack(spacing: 12) {
          if images.count > 1 {
            HStack(spacing: 12) {
              Button(action: onSaveCurrent) {
                Text("현재 사진만 저장")
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

              Button(action: onSaveAll) {
                Text("일괄 저장 (\(images.count)장)")
                  .font(TypographyToken.pretendardBody1.font)
                  .bold()
                  .foregroundStyle(ColorToken.grayScale60.color)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(
                    ColorToken.mainAccent.color,
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                  )
                  .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
              }
            }
            .padding(.horizontal, 20)
          } else {
            Button(action: onSaveCurrent) {
              Text("저장하기")
                .font(TypographyToken.pretendardBody1.font)
                .bold()
                .foregroundStyle(ColorToken.grayScale60.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                  ColorToken.mainAccent.color,
                  in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .padding(.horizontal, 20)
          }

          Button {
            showBoastSheet = true
          } label: {
            Text("자랑하기")
              .font(TypographyToken.pretendardBody2.font)
              .bold()
              .foregroundStyle(ColorToken.mainAccent.color)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 10)
              .buttonHitArea(Rectangle())
          }
        }

      case .saved:
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 52))
          .foregroundStyle(ColorToken.mainAccent.color)
        Text("사진 앨범에 저장되었습니다!")
          .font(TypographyToken.pretendardBody1.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale0.color)

        Button(action: onDismiss) {
          Text("닫기")
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale60.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(ColorToken.brandDeepSprout.color, in: RoundedRectangle(cornerRadius: 8))
            .buttonHitArea(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.horizontal, 20)

      case let .failed(message):
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
        .padding(.horizontal, 20)

      case .idle, .picking:
        EmptyView()
      }

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
    .sheet(isPresented: $showBoastSheet) {
      NavigationStack {
        CommunityPostView(
          mode: .create,
          preloadedImages: boastPreloadedImages
        ) { _ in }
      }
    }
  }
}
