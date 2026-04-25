import SwiftUI

struct MainView: View {
  var body: some View {
    TabScreenView(
      title: "홈",
      subtitle: "추천 필터와 주요 콘텐츠를 확인하는 시작 화면입니다.",
      symbolName: IconToken.home.symbolName
    )
  }
}
