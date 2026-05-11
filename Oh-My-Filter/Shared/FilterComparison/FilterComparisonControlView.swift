import SwiftUI

struct FilterComparisonControlView: View {
  @Binding var splitRatio: Double

  var body: some View {
    GeometryReader { proxy in
      let width = proxy.size.width
      let splitX = width * splitRatio

      // After 라벨: offset = max(splitX - 64, 0), 왼쪽 끝에 붙으면(offset == 0) 숨김
      // Before 라벨: offset = min(splitX + 16, width - 48), 오른쪽 끝에 붙으면(offset == width - 48) 숨김
      // Circle 이동 제한: After 라벨이 끝에 안 붙은 상태에서 Circle이 라벨 우측(splitX - 16)에 닿지 않도록 → minSplitX = 64
      //                   Before 라벨이 끝에 안 붙은 상태에서 Circle이 라벨 좌측(splitX + 16)에 닿지 않도록 → maxSplitX = width - 64
      let afterLabelOffset = max(splitX - 64, 0)
      let beforeLabelOffset = min(splitX + 16, width - 48)
      let afterLabelAtEdge = afterLabelOffset == 0
      let beforeLabelAtEdge = beforeLabelOffset == width - 48

      ZStack(alignment: .leading) {
        Text("After")
          .font(TypographyToken.pretendardCaption2.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale45.color)
          .frame(width: 48, height: 20)
          .background(ColorToken.grayScale75.color.opacity(0.5), in: Capsule())
          .offset(x: afterLabelOffset)
          .opacity(afterLabelAtEdge ? 0 : 1)

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
          .offset(x: min(max(splitX - 12, 0), max(width - 24, 0)))
          .gesture(
            DragGesture(coordinateSpace: .named("control"))
              .onChanged { value in
                let minX = afterLabelAtEdge ? 0.0 : 64.0
                let maxX = beforeLabelAtEdge ? width : width - 64
                splitRatio = min(max(value.location.x / width, minX / width), maxX / width)
              }
          )

        Text("Before")
          .font(TypographyToken.pretendardCaption2.font)
          .bold()
          .foregroundStyle(ColorToken.grayScale45.color)
          .frame(width: 48, height: 20)
          .background(ColorToken.grayScale75.color.opacity(0.5), in: Capsule())
          .offset(x: beforeLabelOffset)
          .opacity(beforeLabelAtEdge ? 0 : 1)
      }
      .coordinateSpace(.named("control"))
    }
    .frame(height: 24)
  }
}
