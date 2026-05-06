import SwiftUI

struct FilterComparisonControlView: View {
  @Binding var splitRatio: Double

  var body: some View {
    GeometryReader { proxy in
      let splitX = proxy.size.width * splitRatio
      ZStack(alignment: .leading) {
        Text("After")
          .font(TypographyToken.pretendardCaption2.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale45.color)
          .frame(width: 48, height: 20)
          .background(ColorToken.grayScale75.color.opacity(0.5), in: Capsule())
          .offset(x: max(splitX - 64, 0))

        Circle()
          .fill(ColorToken.grayScale75.color.opacity(0.5))
          .frame(width: 24, height: 24)
          .overlay {
            Image(systemName: "arrow.left.and.right")
              .font(.system(size: 10))
              .foregroundStyle(ColorToken.grayScale45.color)
          }
          .overlay {
            Circle()
              .stroke(ColorToken.grayScale60.color, lineWidth: 2)
          }
          .offset(x: min(max(splitX - 12, 0), max(proxy.size.width - 24, 0)))
          .gesture(
            DragGesture(coordinateSpace: .named("control"))
              .onChanged { value in
                splitRatio = min(max(value.location.x / proxy.size.width, 0.08), 0.92)
              }
          )

        Text("Before")
          .font(TypographyToken.pretendardCaption2.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale45.color)
          .frame(width: 48, height: 20)
          .background(ColorToken.grayScale75.color.opacity(0.5), in: Capsule())
          .offset(x: min(splitX + 16, max(proxy.size.width - 48, 0)))
      }
      .coordinateSpace(.named("control"))
    }
    .frame(height: 24)
  }
}
