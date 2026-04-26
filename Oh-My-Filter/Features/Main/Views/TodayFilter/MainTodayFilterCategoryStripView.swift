import SwiftUI

struct MainTodayFilterCategoryStripView: View {
  var body: some View {
    HStack(spacing: 12) {
      ForEach(MainTodayFilterCategoryItems.all) { item in
        MainTodayFilterCategoryChipView(item: item)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
