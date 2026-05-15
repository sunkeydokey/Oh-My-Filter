import Kingfisher
import SwiftUI

struct FeedContentView: View {
  let sort: FeedSort
  let isInitialLoading: Bool
  let topRankingFilters: [FeedFilter]
  let filters: [FeedFilter]
  let errorMessage: String?
  let isLoadingMore: Bool
  let paginationErrorMessage: String?
  let onSortChanged: (FeedSort) -> Void
  let onFilterSelected: (String) -> Void
  let onRetry: () -> Void
  let onFilterAppeared: (FeedFilter) -> Void

  var body: some View {
    topRankingSection
    feedSection
  }

  private var topRankingSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      ViewThatFits {
        HStack {
          topRankingTitle

          Spacer()

          sortChips
        }

        VStack(alignment: .leading, spacing: 12) {
          topRankingTitle
          sortChips
        }
      }
      .padding(.horizontal, 20)

      ScrollView(.horizontal) {
        LazyHStack(spacing: 14) {
          if isInitialLoading {
            ForEach(0 ..< 3, id: \.self) { index in
              FeedRankingSkeletonCard(rank: index + 1)
            }
          } else {
            ForEach(Array(topRankingFilters.enumerated()), id: \.element.id) { index, filter in
              Button {
                onFilterSelected(filter.id)
              } label: {
                FeedRankingCard(filter: filter, rank: index + 1)
              }
              .buttonStyle(.plain)
            }
          }
        }
        .padding(.horizontal, 20)
      }
      .scrollIndicators(.hidden)
    }
  }

  private var feedSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .center) {
        Text("Filter Feed")
          .font(TypographyToken.pretendardTitle1.font)
          .foregroundStyle(ColorToken.grayScale0.color)

        Spacer()
      }
      .padding(.horizontal, 20)

      if isInitialLoading {
        FeedLoadingGridView()
          .padding(.horizontal, 20)
      } else if let errorMessage {
        FeedErrorView(message: errorMessage, retry: onRetry)
          .padding(.horizontal, 20)
      } else if filters.isEmpty {
        FeedEmptyView()
          .padding(.horizontal, 20)
      } else {
        feedGrid
          .padding(.horizontal, 20)
      }
    }
  }

  private var sortChips: some View {
    HStack(spacing: 8) {
      ForEach(FeedSort.allCases, id: \.self) { feedSort in
        Button {
          onSortChanged(feedSort)
        } label: {
          Text(feedSort.title)
            .font(TypographyToken.pretendardCaption1.font)
            .foregroundStyle(sort == feedSort ? ColorToken.brandBlackSprout.color : ColorToken.grayScale15.color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(sort == feedSort ? ColorToken.grayScale0.color : ColorToken.grayScale100.color, in: Capsule())
            .overlay {
              Capsule()
                .stroke(ColorToken.grayScale90.color.opacity(sort == feedSort ? 0 : 0.6), lineWidth: 1)
            }
            .buttonHitArea(Capsule())
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var topRankingTitle: some View {
    Text("Top Ranking")
      .font(TypographyToken.pretendardTitle1.font)
      .foregroundStyle(ColorToken.grayScale0.color)
  }

  private var feedGrid: some View {
    let spacing: CGFloat = 12
    let columns = filters.masonryColumns(columnCount: 2)

    return VStack(spacing: 16) {
      HStack(alignment: .top, spacing: spacing) {
        ForEach(columns.indices, id: \.self) { columnIndex in
          LazyVStack(spacing: 16) {
            ForEach(columns[columnIndex]) { filter in
              Button {
                onFilterSelected(filter.id)
              } label: {
                FeedFilterCard(filter: filter)
              }
              .buttonStyle(.plain)
              .task {
                onFilterAppeared(filter)
              }
            }
          }
          .frame(maxWidth: .infinity)
        }
      }

      if isLoadingMore {
        ProgressView()
          .tint(ColorToken.mainAccent.color)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 20)
      }

      if let paginationErrorMessage {
        Text(paginationErrorMessage)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 12)
      }
    }
  }
}

private extension Array where Element == FeedFilter {
  func masonryColumns(columnCount: Int) -> [[FeedFilter]] {
    guard columnCount > 0 else { return [] }

    return enumerated().reduce(into: [[FeedFilter]](repeating: [], count: columnCount)) { columns, pair in
      columns[pair.offset % columnCount].append(pair.element)
    }
  }
}

private struct FeedRankingCard: View {
  let filter: FeedFilter
  let rank: Int

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      FeedRemoteImage(url: filter.imageURL)
        .frame(width: 220, height: 380)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

      LinearGradient(
        colors: [
          .clear,
          ColorToken.brandBlackSprout.color.opacity(0.88),
        ],
        startPoint: .top,
        endPoint: .bottom
      )

      VStack(alignment: .leading, spacing: 8) {
        Text("#\(rank)")
          .font(TypographyToken.pretendardBody1.font)
          .foregroundStyle(ColorToken.brandBlackSprout.color)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(ColorToken.mainAccent.color, in: Capsule())

        VStack(alignment: .leading, spacing: 4) {
          Text(filter.title)
            .font(TypographyToken.pretendardBody1.font)
            .foregroundStyle(ColorToken.grayScale0.color)
            .lineLimit(2)

          Text(filter.creatorNick ?? "Unknown")
            .font(TypographyToken.pretendardCaption1.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .lineLimit(1)

          if let category = filter.category {
            Text(category)
              .font(TypographyToken.pretendardCaption2.font)
              .foregroundStyle(ColorToken.grayScale60.color)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(ColorToken.brandDeepSprout.color, in: Capsule())
          }
        }
      }
      .padding(14)
    }
    .frame(width: 220, height: 380)
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    }
  }
}

private struct FeedFilterCard: View {
  let filter: FeedFilter

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      FeedRemoteImage(url: filter.imageURL, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

      VStack(alignment: .leading, spacing: 6) {
        Text(filter.title)
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.grayScale0.color)
          .lineLimit(2)

        Text(filter.creatorNick ?? "Unknown")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .lineLimit(1)

        HStack(spacing: 8) {
          Label(filter.likeCount.formatted(.number), systemImage: "heart.fill")
          Label(filter.buyerCount.formatted(.number), systemImage: "bag.fill")
        }
        .font(TypographyToken.pretendardCaption2.font)
        .foregroundStyle(ColorToken.grayScale45.color)
      }
      .padding(.horizontal, 10)
      .padding(.bottom, 10)
    }
    .background(ColorToken.grayScale100.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    .overlay {
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(ColorToken.grayScale90.color.opacity(0.55), lineWidth: 1)
    }
  }
}

private struct FeedRemoteImage: View {
  let url: URL?
  var contentMode: SwiftUI.ContentMode = .fill

  var body: some View {
    Group {
      if let url {
        KFImage(url)
          .requestModifier(AuthenticatedRemoteImageSupport.requestModifier)
          .placeholder {
            FeedImageFallbackView()
              .aspectRatio(1, contentMode: .fit)
          }
          .resizable()
          .aspectRatio(contentMode: contentMode)
      } else {
        FeedImageFallbackView()
          .aspectRatio(1, contentMode: .fit)
      }
    }
    .clipped()
  }
}

private struct FeedImageFallbackView: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [
          ColorToken.brandDeepSprout.color,
          ColorToken.grayScale90.color,
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Image(systemName: "camera.filters")
        .font(.system(size: 28, weight: .regular))
        .foregroundStyle(ColorToken.grayScale60.color)
    }
  }
}

private struct FeedRankingSkeletonCard: View {
  let rank: Int

  var body: some View {
    RoundedRectangle(cornerRadius: 8, style: .continuous)
      .fill(ColorToken.grayScale90.color.opacity(0.45))
      .frame(width: 220, height: 380)
      .overlay(alignment: .bottomLeading) {
        Text("#\(rank)")
          .font(TypographyToken.pretendardBody1.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .padding(14)
      }
  }
}

private struct FeedLoadingGridView: View {
  var body: some View {
    let columns = [
      GridItem(.flexible(), spacing: 12),
      GridItem(.flexible(), spacing: 12),
    ]

    LazyVGrid(columns: columns, spacing: 16) {
      ForEach(0 ..< 6, id: \.self) { index in
        VStack(alignment: .leading, spacing: 10) {
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(ColorToken.grayScale90.color.opacity(0.45))
            .frame(height: index.isMultiple(of: 3) ? 210 : 166)

          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(ColorToken.grayScale75.color.opacity(0.45))
            .frame(height: 14)

          RoundedRectangle(cornerRadius: 4, style: .continuous)
            .fill(ColorToken.grayScale75.color.opacity(0.35))
            .frame(width: 80, height: 12)
        }
        .padding(10)
        .background(ColorToken.grayScale100.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
    }
  }
}

private struct FeedErrorView: View {
  let message: String
  let retry: () -> Void

  var body: some View {
    VStack(spacing: 14) {
      Text(message)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale45.color)

      Button(action: retry) {
        Text("다시 시도")
          .font(TypographyToken.pretendardBody2.font)
          .foregroundStyle(ColorToken.brandBlackSprout.color)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          .background(ColorToken.mainAccent.color, in: Capsule())
          .buttonHitArea(Capsule())
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 36)
  }
}

private struct FeedEmptyView: View {
  var body: some View {
    Text("아직 표시할 필터가 없습니다.")
      .font(TypographyToken.pretendardBody2.font)
      .foregroundStyle(ColorToken.grayScale45.color)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 36)
  }
}
