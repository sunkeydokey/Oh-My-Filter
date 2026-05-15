import Kingfisher
import PhotosUI
import SwiftUI
import UIKit

struct CommunityPostInputSection<Content: View>: View {
  let title: String
  let error: String?
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(title)
        .font(TypographyToken.pretendardCaption1.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale30.color)

      content()
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))

      if let error {
        Text(error)
          .font(TypographyToken.pretendardCaption2.font)
          .foregroundStyle(ColorToken.mainAccent.color)
      }
    }
  }
}

struct CommunityEditableImageSectionView: View {
  let existingFilePaths: [String]
  let selectedImages: [PhotoPickerUploadSelection]
  let convertingSelectionID: UUID?
  let onSelectionChanged: ([PhotoPickerUploadSelection]) -> Void
  let onRemoveExisting: (String) -> Void
  let onConvertToAnime: (UUID) -> Void
  let onSaveLocalImage: (UUID) -> Void

  @State private var pickerItems: [PhotosPickerItem] = []

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("미디어 추가")
        .font(TypographyToken.pretendardCaption1.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale30.color)

      ScrollView(.horizontal) {
        HStack(spacing: 10) {
          ForEach(existingFilePaths, id: \.self) { path in
            CommunityExistingImageTileView(path: path) {
              onRemoveExisting(path)
            }
          }

          ForEach(selectedImages) { selection in
            CommunityLocalImageTileView(
              selection: selection,
              isConverting: convertingSelectionID == selection.id,
              onConvert: selection.mediaKind == .image ? { onConvertToAnime(selection.id) } : nil,
              onSave: selection.mediaKind == .image ? { onSaveLocalImage(selection.id) } : nil
            )
          }

          PhotosPicker(
            selection: $pickerItems,
            maxSelectionCount: ImageUploadPreset.communityPost.maxCount,
            matching: .any(of: [.images, .videos])
          ) {
            VStack(spacing: 8) {
              Image(systemName: "photo.badge.plus")
                .font(.system(size: 24, weight: .semibold))
              Text("미디어 추가")
                .font(TypographyToken.pretendardCaption1.font.weight(.bold))
            }
            .foregroundStyle(ColorToken.grayScale45.color)
            .frame(width: max(existingFilePaths.isEmpty && selectedImages.isEmpty ? 350 : 116, 116), height: 116)
            .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ColorToken.grayScale90.color.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
          }
        }
      }
      .scrollIndicators(.hidden)
    }
    .onChange(of: pickerItems) { _, items in
      Task {
        var selections: [PhotoPickerUploadSelection] = []
        for (index, item) in items.prefix(ImageUploadPreset.communityPost.maxCount).enumerated() {
          guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
          let contentType = item.supportedContentTypes.first(where: { $0.conforms(to: .movie) })
            ?? item.supportedContentTypes.first
          let isVideo = contentType?.conforms(to: .movie) == true
          selections.append(PhotoPickerUploadSelection(
            data: data,
            baseName: isVideo ? "post-video-\(index + 1)" : "post-image-\(index + 1)",
            mediaKind: isVideo ? .video : .image,
            preferredType: contentType
          ))
        }
        onSelectionChanged(selections)
      }
    }
  }
}

private struct CommunityExistingImageTileView: View {
  let path: String
  let onRemove: () -> Void

  var body: some View {
    ZStack(alignment: .topTrailing) {
      KFImage(AuthenticatedRemoteImageSupport.url(from: path))
        .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
        .placeholder {
          CommunityPostImagePlaceholderView()
        }
        .resizable()
        .scaledToFill()
        .frame(width: 116, height: 116)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

      Button(action: onRemove) {
        Image(systemName: "xmark")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(ColorToken.grayScale0.color)
          .frame(width: 24, height: 24)
          .background(ColorToken.brandBlackSprout.color.opacity(0.78), in: Circle())
      }
      .buttonStyle(.plain)
      .padding(6)
    }
  }
}

private struct CommunityLocalImageTileView: View {
  let selection: PhotoPickerUploadSelection
  var isConverting: Bool = false
  var onConvert: (() -> Void)? = nil
  var onSave: (() -> Void)? = nil

  var body: some View {
    Group {
      if selection.mediaKind == .video {
        ZStack {
          CommunityPostImagePlaceholderView()
          Image(systemName: "play.circle.fill")
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(ColorToken.grayScale0.color)
        }
      } else if let image = UIImage(data: selection.data) {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        CommunityPostImagePlaceholderView()
      }
    }
    .frame(width: 116, height: 116)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay(alignment: .bottomLeading) {
      if let onConvert {
        Button(action: onConvert) {
          Image(systemName: "wand.and.sparkles")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(isConverting ? ColorToken.grayScale100.color : ColorToken.grayScale0.color)
            .frame(width: 24, height: 24)
            .background(
              isConverting ? ColorToken.mainAccent.color.opacity(0.88) : ColorToken.brandBlackSprout.color.opacity(0.78),
              in: Circle()
            )
        }
        .buttonStyle(.plain)
        .disabled(isConverting)
        .padding(6)
      }
    }
    .overlay(alignment: .bottomTrailing) {
      if let onSave {
        Button(action: onSave) {
          Image(systemName: "arrow.down.to.line")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(ColorToken.grayScale0.color)
            .frame(width: 24, height: 24)
            .background(ColorToken.brandBlackSprout.color.opacity(0.78), in: Circle())
        }
        .buttonStyle(.plain)
        .padding(6)
      }
    }
  }
}

struct CommunityReadOnlyAttachmentCarousel: View {
  let attachments: [CommunityAttachment]
  var onSaveCurrentImage: ((URL) -> Void)? = nil
  var onConvertCurrentImage: ((URL) -> Void)? = nil
  @State private var currentIndex = 0

  var body: some View {
    TabView(selection: $currentIndex) {
      ForEach(Array(attachments.enumerated()), id: \.offset) { index, attachment in
        Group {
          switch attachment {
          case .image(let url):
            CommunityRemotePostImageView(url: url)
          case .video(let url):
            PostVideoPlayerView(url: url)
          }
        }
        .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: attachments.count > 1 ? .automatic : .never))
    .frame(height: 210)
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.45), lineWidth: 1)
    }
    .overlay(alignment: .bottomTrailing) {
      if attachments.count > 1 {
        Text("\(currentIndex + 1) / \(attachments.count)")
          .font(TypographyToken.pretendardCaption2.font.weight(.semibold))
          .foregroundStyle(ColorToken.grayScale0.color)
          .padding(.horizontal, 8)
          .frame(height: 26)
          .background(ColorToken.brandBlackSprout.color.opacity(0.72), in: Capsule())
          .padding(10)
      }
    }
    .overlay(alignment: .bottomLeading) {
      if let onSave = onSaveCurrentImage,
         attachments.indices.contains(currentIndex),
         case .image(let url) = attachments[currentIndex]
      {
        Button { onSave(url) } label: {
          Image(systemName: "arrow.down.to.line")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ColorToken.grayScale0.color)
            .frame(width: 32, height: 32)
            .background(ColorToken.brandBlackSprout.color.opacity(0.72), in: Circle())
        }
        .buttonStyle(.plain)
        .padding(10)
      }
    }
    .overlay(alignment: .topTrailing) {
      if let onConvert = onConvertCurrentImage,
         attachments.indices.contains(currentIndex),
         case .image(let url) = attachments[currentIndex]
      {
        Button { onConvert(url) } label: {
          Image(systemName: "wand.and.sparkles")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(ColorToken.grayScale0.color)
            .frame(width: 32, height: 32)
            .background(ColorToken.brandBlackSprout.color.opacity(0.72), in: Circle())
        }
        .buttonStyle(.plain)
        .padding(10)
      }
    }
  }
}

private struct CommunityRemotePostImageView: View {
  let url: URL

  var body: some View {
    KFImage(url)
      .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
      .placeholder {
        CommunityPostImagePlaceholderView()
      }
      .resizable()
      .scaledToFill()
      .background(ColorToken.brandBlackSprout.color)
      .clipped()
  }
}

struct CommunityPostImagePlaceholderView: View {
  var body: some View {
    ZStack {
      ColorToken.brandBlackSprout.color
      Image(systemName: "photo")
        .font(.system(size: 24, weight: .regular))
        .foregroundStyle(ColorToken.grayScale60.color)
    }
  }
}

struct CommunityPostAvatarView: View {
  let url: URL?

  var body: some View {
    KFImage(url)
      .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
      .placeholder {
        Circle()
          .fill(ColorToken.brandBlackSprout.color)
          .overlay {
            Image(systemName: "person.fill")
              .font(.system(size: 16, weight: .regular))
              .foregroundStyle(ColorToken.grayScale60.color)
          }
      }
      .resizable()
      .scaledToFill()
      .frame(width: 36, height: 36)
      .clipShape(Circle())
  }
}

struct CommunityPostActionButton: View {
  let title: String
  let systemImage: String?
  let isPrimary: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if let systemImage {
          Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
        }
        Text(title)
          .font(TypographyToken.pretendardCaption1.font.weight(.bold))
      }
      .foregroundStyle(isPrimary ? ColorToken.grayScale100.color : ColorToken.grayScale45.color)
      .padding(.horizontal, 14)
      .frame(height: 42)
      .background(isPrimary ? ColorToken.mainAccent.color : ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
      .buttonHitArea(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    .buttonStyle(.plain)
  }
}

struct CommunityPostLoadingView: View {
  let title: String

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(title)
        .font(.custom(TypographyToken.mulgyeolTitle1.fontName, size: 20, relativeTo: .headline))
        .foregroundStyle(ColorToken.grayScale30.color)
        .frame(maxWidth: .infinity, minHeight: 44)

      ForEach(0 ..< 7, id: \.self) { index in
        RoundedRectangle(cornerRadius: 8, style: .continuous)
          .fill(ColorToken.brandBlackSprout.color)
          .frame(height: index == 3 ? 142 : 44)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 18)
  }
}

struct CommunityPostErrorView: View {
  let title: String
  let message: String
  let retry: () -> Void

  var body: some View {
    VStack(spacing: 20) {
      Text(title)
        .font(.custom(TypographyToken.mulgyeolTitle1.fontName, size: 20, relativeTo: .headline))
        .foregroundStyle(ColorToken.grayScale30.color)
        .frame(height: 44)

      Spacer()

      Text(message)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale45.color)

      Button(action: retry) {
        Text("다시 시도")
          .font(TypographyToken.pretendardBody2.font.weight(.bold))
          .foregroundStyle(ColorToken.grayScale100.color)
          .padding(.horizontal, 16)
          .frame(height: 42)
          .background(ColorToken.mainAccent.color, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
          .buttonHitArea(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }

      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 18)
  }
}

extension String {
  var communityPostDisplayDate: String {
    if let date = try? Date(self, strategy: .iso8601) {
      return date.formatted(date: .numeric, time: .omitted)
    }
    return self
  }
}
