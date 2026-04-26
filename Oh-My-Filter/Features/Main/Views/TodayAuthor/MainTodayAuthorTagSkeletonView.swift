import SwiftUI

struct MainTodayAuthorTagSkeletonView: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 12, style: .continuous)
      .fill(ColorToken.grayScale75.color.opacity(0.4))
      .frame(width: 64, height: 24)
  }
}
