import SwiftUI

struct FilterDetailValuesView: View {
  let values: FilterValues
  let isLocked: Bool

  var body: some View {
    FilterPanelView(title: "Filter Presets", trailing: "LUT") {
      LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 16)], spacing: 16) {
        ForEach(values.displayItems) { item in
          FilterInfoItemView(title: item.title, value: item.valueText)
        }
      }
      .overlay {
        if isLocked {
          FilterDetailLockedOverlayView()
            .padding(-12)
        }
      }
    }
  }
}
