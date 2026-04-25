import SwiftUI

struct ProfileView: View {
  var body: some View {
    TabScreenView(
      title: "프로필",
      subtitle: "계정 정보와 개인 설정을 모아보는 영역입니다.",
      symbolName: IconToken.profile.symbolName
    )
  }
}
