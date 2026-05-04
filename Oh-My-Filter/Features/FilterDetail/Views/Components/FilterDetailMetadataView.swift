import SwiftUI

struct FilterDetailMetadataView: View {
  let title: String
  let trailing: String
  let rows: [(String, String)]
  let isCompact: Bool

  init(metadata: FilterDetailMetadata) {
    self.title = metadata.headerValue
    self.trailing = "EXIF"
    self.rows = metadata.displayRows
    self.isCompact = false
  }

  init(
    title: String,
    trailing: String,
    rows: [(String, String)],
    isCompact: Bool = false
  ) {
    self.title = title
    self.trailing = trailing
    self.rows = rows
    self.isCompact = isCompact
  }

  var body: some View {
    FilterPanelView(title: title, trailing: trailing) {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 72 : 92), spacing: 12)], spacing: 12) {
        ForEach(rows, id: \.0) { label, value in
          FilterInfoItemView(title: label, value: value)
        }
      }
    }
  }
}
