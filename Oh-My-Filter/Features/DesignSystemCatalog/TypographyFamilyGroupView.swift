import SwiftUI

struct TypographyFamilyGroupView: View {
  let familyName: String
  let tokens: [TypographyToken]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(familyName)
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.brandBlackSprout.color)

      VStack(spacing: 10) {
        ForEach(tokens, id: \.self) { token in
          TypographyTokenRowView(token: token)
        }
      }
    }
  }
}
