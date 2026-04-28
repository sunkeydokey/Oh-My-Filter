import SwiftUI

struct FilterImageComparisonView: View {
  let previewState: FilterDetailPreviewState
  @State private var splitRatio = 0.28

  var body: some View {
    VStack(spacing: 12) {
      GeometryReader { proxy in
        let splitX = proxy.size.width * splitRatio

        ZStack(alignment: .leading) {
          FilterDetailPreviewImage(kind: .before, previewState: previewState)
            .frame(width: proxy.size.width, height: proxy.size.height)

          FilterDetailPreviewImage(kind: .after, previewState: previewState)
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
              splitRatio = min(max(value.location.x / max(proxy.size.width, 1), 0.08), 0.92)
            }
        )
      }
      .aspectRatio(350.0 / 384.0, contentMode: .fit)

      FilterDetailCompareControlView(splitRatio: $splitRatio)
    }
  }
}
