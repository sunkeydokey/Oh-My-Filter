import SwiftUI

struct FilterImageComparisonView: View {
  let previewState: FilterComparisonPreviewState
  @State private var splitRatio = 0.28

  var body: some View {
    VStack(spacing: 12) {
      GeometryReader { proxy in
        let splitX = proxy.size.width * splitRatio

        ZStack(alignment: .leading) {
          FilterComparisonImageView(kind: .before, previewState: previewState)
            .frame(width: proxy.size.width, height: proxy.size.height)

          FilterComparisonImageView(kind: .after, previewState: previewState)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .mask(alignment: .leading) {
              Rectangle()
                .frame(width: splitX)
            }

          Rectangle()
            .fill(ColorToken.grayScale45.color)
            .frame(width: 1)
            .offset(x: splitX)
        }
        .clipShape(.rect(cornerRadius: 24))
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { value in
              let w = max(proxy.size.width, 1)
              let x = value.location.x
              // After 라벨이 끝에 붙기 전(splitX > 64)엔 64 미만으로 못 가게
              // Before 라벨이 끝에 붙기 전(splitX < w - 64)엔 w - 64 초과로 못 가게
              let minX = splitRatio > 64 / w ? 64.0 : 0.0
              let maxX = splitRatio < (w - 64) / w ? w - 64 : w
              splitRatio = min(max(x / w, minX / w), maxX / w)
            }
        )
      }
      .aspectRatio(350.0 / 384.0, contentMode: .fit)

      FilterComparisonControlView(splitRatio: $splitRatio)
    }
  }
}
