import SwiftUI

struct SearchView: View {
  var body: some View {
    TabScreenView(
      title: "검색",
      subtitle: "필터와 콘텐츠를 빠르게 찾는 화면입니다.",
      symbolName: IconToken.search.symbolName
    )
  }
}
