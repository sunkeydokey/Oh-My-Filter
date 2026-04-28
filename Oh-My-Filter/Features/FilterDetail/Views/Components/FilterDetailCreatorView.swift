import Kingfisher
import SwiftUI

struct FilterDetailCreatorView: View {
  let detail: FilterDetail

  var body: some View {
    HStack(spacing: 16) {
      if let profileImageURL = detail.creator.profileImageURL {
        KFImage(profileImageURL)
          .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
          .placeholder {
            FilterDetailCreatorPlaceholderView()
          }
          .resizable()
          .scaledToFill()
          .frame(width: 72, height: 72)
          .clipShape(.circle)
      } else {
        FilterDetailCreatorPlaceholderView()
      }

      VStack(alignment: .leading, spacing: 8) {
        Text(detail.creator.displayName)
          .font(TypographyToken.mulgyeolBody1.font)
          .foregroundStyle(ColorToken.grayScale0.color)

        Text(detail.creator.nick)
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale60.color)
      }
    }
  }
}

struct FilterDetailCreatorPlaceholderView: View {
  var body: some View {
    Circle()
      .fill(ColorToken.brandDeepSprout.color)
      .frame(width: 72, height: 72)
      .overlay {
        Image(systemName: IconToken.profile.symbolName)
          .foregroundStyle(ColorToken.grayScale60.color)
      }
  }
}
