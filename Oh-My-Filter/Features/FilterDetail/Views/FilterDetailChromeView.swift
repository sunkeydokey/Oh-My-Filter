import SwiftUI

struct FilterDetailHeaderView: View {
  let title: String
  let isMine: Bool
  let onBack: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    CustomStackNavigationHeader(
      title: title,
      onBack: onBack
    ) {
      if isMine {
        Menu {
          Button("수정", action: onEdit)
          Button("삭제", role: .destructive, action: onDelete)
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(ColorToken.grayScale45.color)
        }
      } else {
        Color.clear
      }
    }
    .padding(.horizontal, 20)
    .background(ColorToken.brandBlackSprout.color)
  }
}

struct FilterDetailConfirmationOverlayView: View {
  let showsDeleteFilterConfirmation: Bool
  let hasPendingDeleteCommentTarget: Bool
  let alert: FilterDetailAlert?
  let onDismissDeleteFilter: () -> Void
  let onConfirmDeleteFilter: () -> Void
  let onDismissDeleteComment: () -> Void
  let onConfirmDeleteComment: () -> Void
  let onDismissAlert: () -> Void
  let onConfirmAlert: () -> Void

  var body: some View {
    if showsDeleteFilterConfirmation {
      CustomAlertView(
        title: "필터 삭제",
        message: "필터를 삭제할까요?",
        cancelTitle: "취소",
        confirmTitle: "삭제",
        onCancel: onDismissDeleteFilter,
        onConfirm: onConfirmDeleteFilter
      )
    } else if hasPendingDeleteCommentTarget {
      CustomAlertView(
        title: "댓글 삭제",
        message: "댓글을 삭제할까요?",
        cancelTitle: "취소",
        confirmTitle: "삭제",
        onCancel: onDismissDeleteComment,
        onConfirm: onConfirmDeleteComment
      )
    } else if let alert {
      CustomAlertView(
        title: alert.title,
        message: alert.message,
        cancelTitle: alert.cancelTitle,
        confirmTitle: alert.confirmTitle,
        onCancel: onDismissAlert,
        onConfirm: onConfirmAlert
      )
    }
  }
}
