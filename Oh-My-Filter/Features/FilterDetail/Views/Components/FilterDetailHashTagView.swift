import SwiftUI

struct FilterDetailHashTagView: View {
  let hashTags: [String]

  var body: some View {
    if hashTags.isEmpty == false {
      ScrollView(.horizontal) {
        HStack(spacing: 4) {
          ForEach(hashTags, id: \.self) { hashTag in
            Text(hashTag.hasPrefix("#") ? hashTag : "#\(hashTag)")
              .font(TypographyToken.pretendardCaption1.font)
              .foregroundStyle(ColorToken.grayScale45.color)
              .padding(.horizontal, 12)
              .padding(.vertical, 5)
              .background(ColorToken.brandDeepSprout.color, in: Capsule())
          }
        }
      }
      .scrollIndicators(.hidden)
    }
  }
}
