import SwiftUI

struct MainTodayFilterCategoryStripView: View {
  var body: some View {
    HStack(alignment: .center, spacing: 0) {
      Spacer(minLength: 0)

      ForEach(MainTodayFilterCategoryItems.all) { item in
        MainTodayFilterCategoryChipView(item: item)

        Spacer(minLength: 0)
      }
    }
    .frame(maxWidth: .infinity)
  }
}
