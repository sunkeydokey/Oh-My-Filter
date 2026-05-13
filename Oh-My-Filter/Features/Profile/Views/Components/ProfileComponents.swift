import Kingfisher
import SwiftUI

struct ProfileGlassCardModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(14)
      .background(ColorToken.brandBlackSprout.color.opacity(0.78), in: .rect(cornerRadius: 24, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .stroke(ColorToken.grayScale0.color.opacity(0.14), lineWidth: 1)
      }
  }
}

extension View {
  func profileGlassCard() -> some View {
    modifier(ProfileGlassCardModifier())
  }
}

struct ProfileAvatarView: View {
  let profile: MyProfile?
  var size: CGFloat = 64

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
        .fill(
          LinearGradient(
            colors: [ColorToken.mainAccent.color, Color(red: 0.95, green: 0.64, blue: 0.54)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      if let url = AuthenticatedRemoteImageSupport.url(from: profile?.profileImage) {
        KFImage(url)
          .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
          .resizable()
          .scaledToFit()
          .frame(width: size, height: size)
          .clipShape(.rect(cornerRadius: size * 0.34, style: .continuous))
      } else {
        Text(profile?.avatarInitials ?? "MY")
          .font(TypographyToken.pretendardBody1.font.weight(.heavy))
          .foregroundStyle(ColorToken.grayScale100.color)
      }
    }
    .frame(width: size, height: size)
  }
}

struct ProfileSectionTitle: View {
  let title: String

  var body: some View {
    Text(title)
      .font(TypographyToken.pretendardBody2.font.weight(.heavy))
      .foregroundStyle(ColorToken.grayScale0.color)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct ProfileActionRow: View {
  let icon: String
  let title: String
  let subtitle: String
  var tint: Color = ColorToken.mainAccent.color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: icon)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(tint)
          .frame(width: 36, height: 36)
          .background(tint.opacity(0.16), in: .rect(cornerRadius: 14, style: .continuous))

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(TypographyToken.pretendardBody2.font.weight(.heavy))
            .foregroundStyle(ColorToken.grayScale0.color)
          Text(subtitle)
            .font(TypographyToken.pretendardCaption1.font)
            .foregroundStyle(ColorToken.grayScale60.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(ColorToken.grayScale75.color)
      }
      .padding(10)
      .background(ColorToken.grayScale90.color.opacity(0.44), in: .rect(cornerRadius: 18, style: .continuous))
      .buttonHitArea(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}

struct ProfileInfoRow: View {
  let icon: String
  let label: String
  let value: String
  var tint: Color = ColorToken.mainAccent.color

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(tint)
        .frame(width: 36, height: 36)
        .background(tint.opacity(0.16), in: .rect(cornerRadius: 14, style: .continuous))

      VStack(alignment: .leading, spacing: 2) {
        Text(label)
          .font(TypographyToken.pretendardCaption1.font.weight(.bold))
          .foregroundStyle(ColorToken.grayScale60.color)
        Text(value)
          .font(TypographyToken.pretendardBody2.font.weight(.heavy))
          .foregroundStyle(ColorToken.grayScale0.color)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(10)
    .background(ColorToken.grayScale90.color.opacity(0.44), in: .rect(cornerRadius: 18, style: .continuous))
  }
}

struct ProfileFormField: View {
  let label: String
  let placeholder: String
  @Binding var text: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .font(TypographyToken.pretendardCaption1.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale60.color)

      TextField(placeholder, text: $text, axis: .vertical)
        .font(TypographyToken.pretendardBody2.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale0.color)
        .tint(ColorToken.mainAccent.color)
    }
    .padding(12)
    .background(ColorToken.grayScale90.color.opacity(0.44), in: .rect(cornerRadius: 18, style: .continuous))
  }
}

struct OrderHistoryCardView: View {
  let order: OrderHistoryItem
  var onApply: () -> Void = {}

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        filterPreview

        VStack(alignment: .leading, spacing: 6) {
          Text(order.filter.category)
            .font(TypographyToken.pretendardCaption2.font.weight(.heavy))
            .foregroundStyle(ColorToken.mainAccent.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(ColorToken.mainAccent.color.opacity(0.16), in: .capsule)

          Text(order.filter.title)
            .font(TypographyToken.pretendardBody1.font.weight(.heavy))
            .foregroundStyle(ColorToken.grayScale0.color)

          Text(order.filter.description)
            .font(TypographyToken.pretendardCaption1.font)
            .foregroundStyle(ColorToken.grayScale60.color)
            .lineLimit(2)

          Text(creatorText)
            .font(TypographyToken.pretendardCaption1.font.weight(.bold))
            .foregroundStyle(Color(red: 0.95, green: 0.64, blue: 0.54))
        }
      }

      HStack(spacing: 6) {
        metaCell(title: "결제일", value: order.paidAt.formatted(date: .numeric, time: .omitted))
        metaCell(title: "가격", value: order.filter.price.formatted(.number))
      }

      HStack(spacing: 8) {
        Image(systemName: "number")
          .foregroundStyle(ColorToken.grayScale75.color)
        Text("주문번호 \(order.orderCode)")
          .font(TypographyToken.pretendardCaption1.font.weight(.heavy))
          .foregroundStyle(ColorToken.grayScale0.color)
      }
      .padding(10)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(ColorToken.grayScale90.color.opacity(0.38), in: .rect(cornerRadius: 16, style: .continuous))

      Button(action: onApply) {
        Label("갤러리에 적용해보기", systemImage: "camera.filters")
          .font(TypographyToken.pretendardBody2.font.weight(.heavy))
          .foregroundStyle(ColorToken.grayScale100.color)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(ColorToken.mainAccent.color, in: .rect(cornerRadius: 8, style: .continuous))
          .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
      .buttonStyle(.plain)
    }
    .profileGlassCard()
  }

  private var filterPreview: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 20, style: .continuous)
        .fill(
          LinearGradient(
            colors: [ColorToken.mainAccent.color, ColorToken.brandDeepSprout.color, Color(red: 0.95, green: 0.64, blue: 0.54)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      if let url = AuthenticatedRemoteImageSupport.url(from: order.filter.files.first) {
        KFImage(url)
          .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
          .resizable()
          .scaledToFit()
          .frame(width: 72, height: 72)
          .clipShape(.rect(cornerRadius: 20, style: .continuous))
      } else {
        Image(systemName: "photo")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(ColorToken.grayScale100.color)
      }
    }
    .frame(width: 72, height: 72)
  }

  private var creatorText: String {
    let tags = order.filter.creator.hashTags.joined(separator: " ")
    return [order.filter.creator.name, order.filter.creator.nick, tags]
      .compactMap { $0 }
      .filter { $0.isEmpty == false }
      .joined(separator: " · ")
  }

  private func metaCell(title: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      Text(title)
        .font(TypographyToken.pretendardCaption2.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale60.color)
      Text(value)
        .font(TypographyToken.pretendardCaption1.font.weight(.heavy))
        .foregroundStyle(ColorToken.grayScale0.color)
    }
    .padding(10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(ColorToken.grayScale90.color.opacity(0.44), in: .rect(cornerRadius: 16, style: .continuous))
  }
}
