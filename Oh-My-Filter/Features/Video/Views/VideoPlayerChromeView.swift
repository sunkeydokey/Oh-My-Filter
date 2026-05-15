import SwiftUI

struct VideoPlayerNavigationBarView: View {
  let offlineState: OfflineVideoState
  let onBack: () -> Void
  let onDownloadOffline: () -> Void

  var body: some View {
    HStack {
      Button(action: onBack) {
        Image(systemName: "chevron.left")
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(ColorToken.grayScale30.color)
      }

      Spacer()

      Text("Video")
        .font(TypographyToken.mulgyeolBody1.font)
        .foregroundStyle(ColorToken.grayScale60.color)

      Spacer()

      VideoOfflineBarButton(
        state: offlineState,
        onDownloadOffline: onDownloadOffline
      )
    }
    .frame(height: 44)
  }
}

private struct VideoOfflineBarButton: View {
  let state: OfflineVideoState
  let onDownloadOffline: () -> Void

  var body: some View {
    switch state {
    case .none:
      Button(action: onDownloadOffline) {
        Image(systemName: "arrow.down.circle")
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(ColorToken.grayScale60.color)
      }
    case .downloading:
      ProgressView()
        .tint(ColorToken.grayScale60.color)
        .frame(width: 22, height: 22)
    case .saved:
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 22, weight: .medium))
        .foregroundStyle(ColorToken.mainAccent.color)
    }
  }
}
