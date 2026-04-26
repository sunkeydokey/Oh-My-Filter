import SwiftUI

struct MainTodayAuthorFallbackAvatarView: View {
  var body: some View {
    Image(systemName: "person.fill")
      .font(.title3)
      .foregroundStyle(ColorToken.grayScale0.color)
      .frame(width: 72, height: 72)
      .background(ColorToken.grayScale75.color)
  }
}
