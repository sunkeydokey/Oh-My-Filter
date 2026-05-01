import Kingfisher
import SwiftUI

struct FullScreenImageViewer: View {
  let files: [String]
  let initialIndex: Int
  let onDismiss: () -> Void

  @State private var currentIndex: Int

  init(
    files: [String],
    initialIndex: Int,
    onDismiss: @escaping () -> Void
  ) {
    self.files = files
    self.initialIndex = initialIndex
    self.onDismiss = onDismiss
    _currentIndex = State(initialValue: min(max(initialIndex, 0), max(files.count - 1, 0)))
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      Color.black.ignoresSafeArea()

      if files.isEmpty {
        emptyPage
      } else {
        TabView(selection: $currentIndex) {
          ForEach(Array(files.enumerated()), id: \.offset) { index, file in
            imagePage(file)
              .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: files.count > 1 ? .automatic : .never))
        .ignoresSafeArea()
      }

      Button {
        onDismiss()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
          .background(.black.opacity(0.55), in: .circle)
      }
      .padding(.top, 16)
      .padding(.leading, 16)

      if files.isEmpty == false {
        VStack {
          Spacer()
          HStack {
            Spacer()
            Text("\(currentIndex + 1) / \(files.count)")
              .font(TypographyToken.pretendardCaption1.font.weight(.semibold))
              .foregroundStyle(.white)
              .padding(.horizontal, 12)
              .frame(height: 32)
              .background(.black.opacity(0.6), in: .capsule)
              .padding(.trailing, 20)
              .padding(.bottom, 28)
          }
        }
      }
    }
    .onAppear {
      currentIndex = min(max(initialIndex, 0), max(files.count - 1, 0))
    }
  }

  @ViewBuilder
  private func imagePage(_ file: String) -> some View {
    if let url = AuthenticatedRemoteImageSupport.url(from: file) {
      KFImage(url)
        .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
        .placeholder {
          ProgressView()
            .tint(.white)
        }
        .resizable()
        .scaledToFit()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      Image(systemName: "photo")
        .font(.system(size: 48, weight: .regular))
        .foregroundStyle(.white.opacity(0.6))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }

  private var emptyPage: some View {
    Image(systemName: "photo")
      .font(.system(size: 48, weight: .regular))
      .foregroundStyle(.white.opacity(0.6))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
