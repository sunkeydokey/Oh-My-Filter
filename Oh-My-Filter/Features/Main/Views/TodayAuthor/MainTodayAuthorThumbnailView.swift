import Kingfisher
import SwiftUI

struct MainTodayAuthorThumbnailView: View {
  let filter: MainTodayAuthorFilter

  var body: some View {
    ZStack {
      if let imageUrl = filter.imageUrl {
        KFImage(imageUrl)
          .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
          .placeholder {
            MainTodayAuthorThumbnailFallbackView(symbol: "camera.fill")
          }
          .resizable()
          .scaledToFill()
      } else {
        MainTodayAuthorThumbnailFallbackView(symbol: "camera.fill")
      }

      VStack(alignment: .leading, spacing: 2) {
        Spacer(minLength: 0)

        if let category = filter.category {
          Text(category)
            .font(.custom(TypographyToken.pretendardCaption1.fontName, size: 10, relativeTo: .caption2))
            .foregroundStyle(ColorToken.grayScale75.color)
            .lineLimit(1)
        }

        Text(filter.title)
          .font(.custom(TypographyToken.pretendardCaption1.fontName, size: 11, relativeTo: .caption))
          .foregroundStyle(ColorToken.grayScale100.color)
          .lineLimit(2)
      }
      .padding(8)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
      .background(alignment: .bottom) {
        LinearGradient(
          colors: [.clear, ColorToken.grayScale0.color.opacity(0.62)],
          startPoint: .top,
          endPoint: .bottom
        )
      }
    }
    .aspectRatio(1.5, contentMode: .fit)
    .frame(maxWidth: .infinity)
    .clipped()
    .clipShape(.rect(cornerRadius: 4))
    .overlay(
      RoundedRectangle(cornerRadius: 4, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.65), lineWidth: 1)
    )
  }
}
