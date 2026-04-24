import Kingfisher
import SwiftUI

struct MainTodayAuthorView: View {
  let todayAuthor: MainTodayAuthor
  let selectionAction: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("\"\(todayAuthor.nick)\"")
        .font(.custom(TypographyToken.mulgyeolBody1.fontName, size: 14, relativeTo: .body))
        .foregroundStyle(ColorToken.grayScale60.color)
        .fixedSize(horizontal: false, vertical: true)

      Text(todayAuthor.introduction ?? "오늘의 작업 분위기를 소개하는 작성자예요.")
        .font(.custom(TypographyToken.pretendardBody3.fontName, size: 12, relativeTo: .subheadline))
        .lineSpacing(5)
        .foregroundStyle(ColorToken.grayScale60.color)
        .fixedSize(horizontal: false, vertical: true)

      if let description = todayAuthor.description {
        Text(description)
          .font(.custom(TypographyToken.pretendardCaption1.fontName, size: 12, relativeTo: .caption))
          .lineSpacing(4)
          .foregroundStyle(ColorToken.grayScale60.color)
          .fixedSize(horizontal: false, vertical: true)
      }

      HStack(alignment: .center, spacing: 16) {
        Capsule()
          .fill(ColorToken.grayScale90.color)
          .frame(width: 72, height: 72)
          .overlay {
            if let profileImageUrl = todayAuthor.profileImageUrl {
              KFImage(profileImageUrl)
                .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
                .placeholder {
                  MainTodayAuthorFallbackAvatarView()
                }
                .resizable()
                .scaledToFill()
                .clipShape(.circle)
            } else {
              MainTodayAuthorFallbackAvatarView()
            }
          }

        VStack(alignment: .leading, spacing: 6) {
          Text(todayAuthor.nick)
            .font(TypographyToken.mulgyeolBody1.font)
            .foregroundStyle(ColorToken.grayScale0.color)

          Text(todayAuthor.name)
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale75.color)
        }

        Spacer(minLength: 0)
      }

      MainTodayAuthorGalleryView(todayAuthor: todayAuthor, selectionAction: selectionAction)

      MainTodayAuthorTagRowView(hashTags: todayAuthor.hashTags)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.bottom, 16)
  }
}
