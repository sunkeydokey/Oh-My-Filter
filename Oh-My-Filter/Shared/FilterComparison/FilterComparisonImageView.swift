import Kingfisher
import SwiftUI

struct FilterComparisonImageView: View {
  let kind: FilterComparisonImageKind
  let previewState: FilterComparisonPreviewState

  var body: some View {
    Group {
      switch previewState {
      case .rendering:
        FilterImagePlaceholderView()
      case let .rendered(images):
        switch kind {
        case .before:
          Image(decorative: images.original, scale: 1)
            .resizable()
            .scaledToFill()
        case .after:
          Image(decorative: images.filtered, scale: 1)
            .resizable()
            .scaledToFill()
        }
      case let .fallback(originalImageURL, filteredImageURL):
        fallbackImage(originalImageURL: originalImageURL, filteredImageURL: filteredImageURL)
      }
    }
    .clipped()
  }

  @ViewBuilder
  private func fallbackImage(originalImageURL: URL?, filteredImageURL: URL?) -> some View {
    let url = kind == .after ? (filteredImageURL ?? originalImageURL) : originalImageURL
    if let url {
      KFImage(url)
        .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
        .placeholder {
          FilterImagePlaceholderView()
        }
        .resizable()
        .scaledToFill()
    } else {
      FilterImagePlaceholderView()
    }
  }
}
