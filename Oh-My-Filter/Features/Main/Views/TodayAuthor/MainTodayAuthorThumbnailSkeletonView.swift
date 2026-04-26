import SwiftUI

struct MainTodayAuthorThumbnailSkeletonView: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 4, style: .continuous)
      .fill(ColorToken.grayScale75.color.opacity(0.4))
      .aspectRatio(1.5, contentMode: .fit)
      .frame(maxWidth: .infinity)
  }
}
