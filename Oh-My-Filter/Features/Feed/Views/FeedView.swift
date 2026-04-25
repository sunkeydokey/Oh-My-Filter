import SwiftUI

struct FeedView: View {
  var body: some View {
    TabScreenView(
      title: "피드",
      subtitle: "다른 사용자의 필터와 활동을 이어서 볼 수 있습니다.",
      symbolName: IconToken.board.symbolName
    )
  }
}
