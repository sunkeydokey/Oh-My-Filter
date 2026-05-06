import SwiftUI

struct FilterImagePlaceholderView: View {
  var body: some View {
    ZStack {
      ColorToken.brandDeepSprout.color
      Image(systemName: IconToken.magic.symbolName)
        .font(.largeTitle)
        .foregroundStyle(ColorToken.grayScale60.color)
    }
  }
}
