import SwiftUI

struct MainHotTrendSectionView: View {
  let state: MainSectionState<[MainHotTrendFilter]>
  let retryAction: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      MainSectionHeaderView(title: "핫 트렌드")

      if let hotTrendFilters = state.value, hotTrendFilters.isEmpty == false {
        ScrollView(.horizontal) {
          LazyHStack(spacing: 16) {
            ForEach(hotTrendFilters.enumerated(), id: \.element.id) { index, item in
              HotTrendCardView(rank: index + 1, item: item)
            }
          }
        }
        .frame(maxWidth: .infinity)
        .scrollIndicators(.hidden)
      } else {
        MainHotTrendFallbackView(state: state, retryAction: retryAction)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
