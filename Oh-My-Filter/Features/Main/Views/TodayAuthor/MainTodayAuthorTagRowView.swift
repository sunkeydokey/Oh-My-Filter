import SwiftUI

struct MainTodayAuthorTagRowView: View {
  let hashTags: [String]

  var body: some View {
    HStack(spacing: 8) {
      ForEach(hashTags, id: \.self) { hashTag in
        MainTodayAuthorTagChipView(title: hashTag)
      }
    }
  }
}
