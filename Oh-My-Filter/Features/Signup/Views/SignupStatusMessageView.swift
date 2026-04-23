import SwiftUI

struct SignupStatusMessageView: View {
  let message: String
  let isSuccess: Bool

  var body: some View {
    Text(message)
      .font(TypographyToken.pretendardCaption1.font)
      .foregroundStyle(isSuccess ? ColorToken.sesacFilterBrightTurquoise.color : .red)
  }
}
