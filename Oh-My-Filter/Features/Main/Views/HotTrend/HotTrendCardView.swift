import Kingfisher
import SwiftUI

struct HotTrendCardView: View {
  let rank: Int
  let item: MainHotTrendFilter
  let selectionAction: (String) -> Void

  var body: some View {
    Button {
      selectionAction(item.id)
    } label: {
      ZStack(alignment: .topLeading) {
        Group {
          if let imageUrl = item.imageUrl {
            KFImage(imageUrl)
              .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
              .placeholder {
                HotTrendCardFallbackBackgroundView()
              }
              .resizable()
              .scaledToFill()
          } else {
            HotTrendCardFallbackBackgroundView()
          }
        }
        .frame(width: 200, height: 240)
        .clipped()
        .accessibilityLabel(item.title)

        LinearGradient(
          colors: [
            ColorToken.brandBlackSprout.color.opacity(0.04),
            ColorToken.brandBlackSprout.color.opacity(0.48),
            ColorToken.brandBlackSprout.color.opacity(0.9)
          ],
          startPoint: .top,
          endPoint: .bottom
        )

        VStack(alignment: .leading, spacing: 12) {
          HStack(alignment: .top, spacing: 10) {
            Text(item.title)
              .font(.custom(TypographyToken.mulgyeolBody1.fontName, size: 14, relativeTo: .body))
              .foregroundStyle(ColorToken.grayScale0.color)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack(spacing: 3) {
              Image(systemName: "heart.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(ColorToken.brandBlackSprout.color)
                .accessibilityHidden(true)

              Text("\(rank)")
                .font(.custom(TypographyToken.pretendardCaption2.fontName, size: 10, relativeTo: .caption2))
                .foregroundStyle(ColorToken.grayScale0.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(ColorToken.grayScale0.color.opacity(0.16), in: Capsule())
          }

          Spacer(minLength: 0)

          if let creatorName = item.creatorName {
            Text(creatorName)
              .font(TypographyToken.pretendardCaption1.font)
              .foregroundStyle(ColorToken.grayScale45.color)
              .lineLimit(1)
          }
        }
        .padding(12)
        .frame(width: 200, height: 240, alignment: .topLeading)
      }
    }
    .buttonStyle(.plain)
    .frame(width: 200, height: 240)
    .clipShape(.rect(cornerRadius: 8))
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(ColorToken.grayScale75.color.opacity(0.55), lineWidth: 1)
    )
  }
}
