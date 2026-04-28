import SwiftUI

struct FilterDetailMetadataView: View {
  let metadata: FilterDetailMetadata

  var body: some View {
    FilterPanelView(title: metadata.headerValue, trailing: "EXIF") {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)], spacing: 12) {
        ForEach(metadata.displayRows, id: \.0) { label, value in
          FilterInfoItemView(title: label, value: value)
        }
      }
    }
  }
}
