import Kingfisher
import SwiftUI

struct VideoDetailView: View {
  let video: CommunityVideo

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        KFImage(video.thumbnailURL)
          .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
          .placeholder {
            ColorToken.brandBlackSprout.color
          }
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity)
          .aspectRatio(16 / 9, contentMode: .fit)
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        Text(video.title)
          .font(TypographyToken.pretendardTitle1.font)
          .foregroundStyle(ColorToken.grayScale0.color)

        Text("조회 \(video.viewCount.formatted(.number)) · 좋아요 \(video.likeCount.formatted(.number))")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale60.color)

        Text(video.description)
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale30.color)
          .lineSpacing(4)

        if video.availableQualities.isEmpty == false {
          Text(video.availableQualities.joined(separator: " · "))
            .font(TypographyToken.pretendardCaption1.font)
            .foregroundStyle(ColorToken.grayScale60.color)
        }
      }
      .padding(20)
    }
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
    .navigationTitle("동영상")
    .navigationBarTitleDisplayMode(.inline)
  }
}
