import SwiftUI

struct IconTokenGroupView: View {
  let title: String
  let tokens: [IconToken]

  private let columns = [
    GridItem(.adaptive(minimum: 72), spacing: 12, alignment: .top)
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(TypographyToken.pretendardBody1.font)
        .foregroundStyle(ColorToken.brandBlackSprout.color)

      LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
        ForEach(tokens, id: \.self) { token in
          IconTokenChipView(token: token)
        }
      }
    }
  }
}
