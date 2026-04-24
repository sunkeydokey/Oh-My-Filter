import SwiftUI

struct MainTodayAuthorGalleryView: View {
  let todayAuthor: MainTodayAuthor
  let selectionAction: (String) -> Void

  var body: some View {
    HStack(spacing: 12) {
      ForEach(todayAuthor.filters.prefix(3)) { filter in
        MainTodayAuthorThumbnailView(filter: filter, selectionAction: selectionAction)
      }
    }
    .frame(maxWidth: .infinity)
  }
}
