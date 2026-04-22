import SwiftUI

struct TypographyTokenSectionView: View {
  private let familyOrder = ["Pretendard", "학교안심 물결체"]

  var body: some View {
    let groupedTokens = Dictionary(grouping: TypographyToken.allCases, by: \.familyDisplayName)

    return VStack(alignment: .leading, spacing: 20) {
      Text("Typography tokens")
        .font(TypographyToken.pretendardTitle1.font)
        .foregroundStyle(ColorToken.brandBlackSprout.color)

      ForEach(familyOrder, id: \.self) { familyName in
        if let tokens = groupedTokens[familyName] {
          TypographyFamilyGroupView(
            familyName: familyName,
            tokens: tokens.sorted { $0.sortOrder < $1.sortOrder }
          )
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ColorToken.grayScale0.color)
    .clipShape(.rect(cornerRadius: CornerRadiusToken.section.value))
    .overlay {
      RoundedRectangle(cornerRadius: CornerRadiusToken.section.value)
        .stroke(ColorToken.grayScale30.color, lineWidth: 1)
    }
  }
}
