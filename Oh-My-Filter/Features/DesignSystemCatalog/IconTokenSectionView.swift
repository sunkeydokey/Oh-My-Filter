import SwiftUI

struct IconTokenSectionView: View {
  private let groupOrder = ["Action", "Lifestyle", "Navigation", "Utility"]

  var body: some View {
    let groupedTokens = Dictionary(grouping: IconToken.allCases, by: \.groupTitle)

    return VStack(alignment: .leading, spacing: 20) {
      Text("Icon tokens")
        .font(TypographyToken.pretendardTitle1.font)
        .foregroundStyle(ColorToken.brandBlackSprout.color)

      ForEach(groupOrder, id: \.self) { groupTitle in
        if let tokens = groupedTokens[groupTitle] {
          IconTokenGroupView(
            title: groupTitle,
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
