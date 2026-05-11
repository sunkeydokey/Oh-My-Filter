import SwiftUI

struct FilterDetailLoadedView: View {
  let detail: FilterDetail
  let previewState: FilterComparisonPreviewState
  let isPaymentProcessing: Bool
  let isMine: Bool
  let currentUserID: String?
  let expandedReplyCommentIDs: Set<String>
  let replyingToCommentID: String?
  let editingCommentTarget: CommentEditTarget?
  let commentText: String
  let onToggleLike: () -> Void
  let action: () -> Void
  let onApply: () -> Void
  let onPurchaseRequired: () -> Void
  let onCommentTextChanged: (String) -> Void
  let onSubmitComment: () -> Void
  let onReply: (String) -> Void
  let onCancelReply: () -> Void
  let onCancelCommentEdit: () -> Void
  let onToggleReplies: (String) -> Void
  let onEditComment: (String) -> Void
  let onDeleteComment: (String) -> Void
  let onEditReply: (String, String) -> Void
  let onDeleteReply: (String, String) -> Void

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        FilterImageComparisonView(
          previewState: previewState
        )

        FilterDetailPriceView(detail: detail)
        FilterDetailStatsView(detail: detail, onToggleLike: onToggleLike)
        FilterDetailMetadataView(metadata: detail.metadata)
        FilterDetailValuesView(
          values: detail.filterValues,
          isLocked: false
        )

        Button {
          if isMine || detail.isDownloaded {
            onApply()
          } else {
            onPurchaseRequired()
          }
        } label: {
          Text("적용해보기")
            .font(TypographyToken.pretendardBody1.font)
            .bold()
            .foregroundStyle(ColorToken.mainAccent.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
              RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(ColorToken.mainAccent.color, lineWidth: 1.5)
            )
            .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }

        Button {
          if isMine || detail.isDownloaded {
            action()
          } else {
            onPurchaseRequired()
          }
        } label: {
          Text(buttonTitle)
            .font(TypographyToken.pretendardBody1.font)
            .bold()
            .foregroundStyle(isPaymentProcessing ? ColorToken.grayScale0.color : ColorToken.grayScale60.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
              isPaymentProcessing ? ColorToken.grayScale75.color : ColorToken.mainAccent.color,
              in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .buttonHitArea(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .disabled(isPaymentProcessing)

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
          currentUserID: currentUserID,
          expandedReplyCommentIDs: expandedReplyCommentIDs,
          replyingToCommentID: replyingToCommentID,
          editingCommentTarget: editingCommentTarget,
          commentText: commentText,
          onTextChanged: onCommentTextChanged,
          onSubmit: onSubmitComment,
          onReply: onReply,
          onCancelReply: onCancelReply,
          onCancelEdit: onCancelCommentEdit,
          onToggleReplies: onToggleReplies,
          onEditComment: onEditComment,
          onDeleteComment: onDeleteComment,
          onEditReply: onEditReply,
          onDeleteReply: onDeleteReply
        )
      }
      .padding(.horizontal, 20)
      .padding(.bottom, 40)
    }
    .scrollIndicators(.hidden)
  }

  private var buttonTitle: String {
    if isPaymentProcessing { return "결제 처리 중" }
    if isMine { return "내 필터" }
    return detail.buttonTitle
  }
}
