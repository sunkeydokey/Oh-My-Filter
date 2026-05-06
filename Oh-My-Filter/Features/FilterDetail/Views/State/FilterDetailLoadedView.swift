import SwiftUI

struct FilterDetailLoadedView: View {
  let detail: FilterDetail
  let previewState: FilterDetailPreviewState
  let isPaymentProcessing: Bool
  let expandedReplyCommentIDs: Set<String>
  let replyingToCommentID: String?
  let commentText: String
  let action: () -> Void
  let onCommentTextChanged: (String) -> Void
  let onSubmitComment: () -> Void
  let onReply: (String) -> Void
  let onCancelReply: () -> Void
  let onToggleReplies: (String) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        FilterImageComparisonView(
          previewState: previewState
        )

        FilterDetailPriceView(detail: detail)
        FilterDetailStatsView(detail: detail)
        FilterDetailMetadataView(metadata: detail.metadata)
        FilterDetailValuesView(
          values: detail.filterValues,
          isLocked: detail.isDownloaded == false
        )

        Button(buttonTitle, action: action)
          .disabled(detail.isDownloaded || isPaymentProcessing)
          .font(TypographyToken.pretendardBody1.font)
          .bold()
          .foregroundStyle(detail.isDownloaded || isPaymentProcessing ? ColorToken.grayScale0.color : ColorToken.grayScale60.color)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(
            detail.isDownloaded || isPaymentProcessing ? ColorToken.grayScale75.color : ColorToken.sesacFilterBrightTurquoise.color,
            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
          )

        Divider()
          .overlay(ColorToken.grayScale90.color)

        FilterDetailCreatorView(detail: detail)
        FilterDetailHashTagView(hashTags: detail.hashTags)

        Text(detail.description)
          .font(TypographyToken.pretendardBody3.font)
          .lineSpacing(5)
          .foregroundStyle(ColorToken.grayScale45.color)
          .fixedSize(horizontal: false, vertical: true)

        SharedCommentSectionView(
          comments: detail.comments,
          expandedReplyCommentIDs: expandedReplyCommentIDs,
          replyingToCommentID: replyingToCommentID,
          commentText: commentText,
          onTextChanged: onCommentTextChanged,
          onSubmit: onSubmitComment,
          onReply: onReply,
          onCancelReply: onCancelReply,
          onToggleReplies: onToggleReplies
        )
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 40)
    }
    .scrollIndicators(.hidden)
  }

  private var buttonTitle: String {
    isPaymentProcessing ? "결제 처리 중" : detail.buttonTitle
  }
}
