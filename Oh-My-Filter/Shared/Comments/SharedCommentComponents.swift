import SwiftUI

struct SharedCommentSectionView: View {
  let comments: [Comment]
  let currentUserID: String?
  let expandedReplyCommentIDs: Set<String>
  let replyingToCommentID: String?
  let editingCommentTarget: CommentEditTarget?
  let commentText: String
  let onTextChanged: (String) -> Void
  let onSubmit: () -> Void
  let onReply: (String) -> Void
  let onCancelReply: () -> Void
  let onCancelEdit: () -> Void
  let onToggleReplies: (String) -> Void
  let onEditComment: (String) -> Void
  let onDeleteComment: (String) -> Void
  let onEditReply: (String, String) -> Void
  let onDeleteReply: (String, String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if comments.isEmpty {
        SharedEmptyCommentStateView()
      } else {
        Text("댓글")
          .font(TypographyToken.pretendardBody1.font.weight(.bold))
          .foregroundStyle(ColorToken.grayScale30.color)

        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(comments) { comment in
            SharedCommentRowView(
              comment: comment,
              currentUserID: currentUserID,
              isExpanded: expandedReplyCommentIDs.contains(comment.id),
              onReply: { onReply(comment.id) },
              onToggleReplies: { onToggleReplies(comment.id) },
              onEdit: { onEditComment(comment.id) },
              onDelete: { onDeleteComment(comment.id) },
              onEditReply: { replyID in onEditReply(comment.id, replyID) },
              onDeleteReply: { replyID in onDeleteReply(comment.id, replyID) }
            )
          }
        }
      }

      SharedCommentComposerView(
        text: commentText,
        replyingToCommentID: replyingToCommentID,
        isEditing: editingCommentTarget != nil,
        onTextChanged: onTextChanged,
        onSubmit: onSubmit,
        onCancelReply: onCancelReply,
        onCancelEdit: onCancelEdit
      )
    }
  }
}

private struct SharedCommentRowView: View {
  let comment: Comment
  let currentUserID: String?
  let isExpanded: Bool
  let onReply: () -> Void
  let onToggleReplies: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void
  let onEditReply: (String) -> Void
  let onDeleteReply: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top, spacing: 10) {
        SharedCommentAvatarView(size: 32)

        VStack(alignment: .leading, spacing: 5) {
          Text(comment.creator.nick)
            .font(TypographyToken.pretendardCaption1.font.weight(.bold))
            .foregroundStyle(ColorToken.grayScale0.color)

          Text(comment.content)
            .font(TypographyToken.pretendardCaption1.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)

          SharedCommentActionRowView(
            timestamp: comment.createdAt.commentDisplayDate,
            replyTitle: "답글 달기",
            showsOwnerActions: comment.creator.id == currentUserID,
            onReply: onReply,
            onEdit: onEdit,
            onDelete: onDelete
          )
        }
      }
      .padding(.vertical, 12)

      if comment.replies.isEmpty == false {
        SharedReplyGroupView(
          replies: comment.replies,
          currentUserID: currentUserID,
          isExpanded: isExpanded,
          onToggle: onToggleReplies,
          onEdit: onEditReply,
          onDelete: onDeleteReply
        )
      }

      Divider()
        .overlay(ColorToken.grayScale90.color.opacity(0.45))
    }
  }
}

private struct SharedReplyGroupView: View {
  let replies: [CommentReply]
  let currentUserID: String?
  let isExpanded: Bool
  let onToggle: () -> Void
  let onEdit: (String) -> Void
  let onDelete: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button(isExpanded ? "답글 숨기기" : "답글 보기", action: onToggle)
        .font(TypographyToken.pretendardCaption2.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale60.color)
        .buttonStyle(.plain)

      if isExpanded {
        ForEach(replies) { reply in
          SharedReplyRowView(
            reply: reply,
            showsOwnerActions: reply.creator.id == currentUserID,
            onEdit: { onEdit(reply.id) },
            onDelete: { onDelete(reply.id) }
          )
        }
      }
    }
    .padding(.leading, 42)
    .padding(.bottom, 8)
  }
}

private struct SharedReplyRowView: View {
  let reply: CommentReply
  let showsOwnerActions: Bool
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      SharedCommentAvatarView(size: 24)

      VStack(alignment: .leading, spacing: 5) {
        Text(reply.creator.nick)
          .font(TypographyToken.pretendardCaption2.font.weight(.bold))
          .foregroundStyle(ColorToken.grayScale0.color)

        Text(reply.content)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .fixedSize(horizontal: false, vertical: true)

        SharedCommentOwnerActionMenu(
          showsOwnerActions: showsOwnerActions,
          onEdit: onEdit,
          onDelete: onDelete
        )
      }
    }
  }
}

private struct SharedCommentActionRowView: View {
  let timestamp: String
  let replyTitle: String
  let showsOwnerActions: Bool
  let onReply: () -> Void
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Text(timestamp)
        .font(TypographyToken.pretendardCaption2.font)
        .foregroundStyle(ColorToken.grayScale60.color)

      Button(replyTitle, action: onReply)
        .font(TypographyToken.pretendardCaption2.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale60.color)
        .buttonStyle(.plain)

      SharedCommentOwnerActionMenu(
        showsOwnerActions: showsOwnerActions,
        onEdit: onEdit,
        onDelete: onDelete
      )
    }
  }
}

private struct SharedCommentOwnerActionMenu: View {
  let showsOwnerActions: Bool
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    if showsOwnerActions {
      Menu {
        Button("수정", action: onEdit)
        Button("삭제", role: .destructive, action: onDelete)
      } label: {
        Image(systemName: "ellipsis")
          .font(.system(size: 13, weight: .semibold))
          .frame(width: 24, height: 18)
          .foregroundStyle(ColorToken.grayScale60.color)
      }
      .buttonStyle(.plain)
    }
  }
}

private struct SharedCommentComposerView: View {
  let text: String
  let replyingToCommentID: String?
  let isEditing: Bool
  let onTextChanged: (String) -> Void
  let onSubmit: () -> Void
  let onCancelReply: () -> Void
  let onCancelEdit: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if isEditing {
        HStack(spacing: 8) {
          Text("수정")
            .font(TypographyToken.pretendardCaption2.font.weight(.bold))
            .foregroundStyle(ColorToken.mainAccent.color)

          Button("취소", action: onCancelEdit)
            .font(TypographyToken.pretendardCaption2.font.weight(.bold))
            .foregroundStyle(ColorToken.grayScale60.color)
            .buttonStyle(.plain)
        }
      } else if replyingToCommentID != nil {
        HStack(spacing: 8) {
          Text("답글")
            .font(TypographyToken.pretendardCaption2.font.weight(.bold))
            .foregroundStyle(ColorToken.mainAccent.color)

          Button("취소", action: onCancelReply)
            .font(TypographyToken.pretendardCaption2.font.weight(.bold))
            .foregroundStyle(ColorToken.grayScale60.color)
            .buttonStyle(.plain)
        }
      }

      HStack(spacing: 10) {
        TextField("댓글을 입력하세요", text: Binding(
          get: { text },
          set: onTextChanged
        ), axis: .vertical)
        .font(TypographyToken.pretendardBody2.font)
        .foregroundStyle(ColorToken.grayScale0.color)
        .lineLimit(1...4)

        Button(action: onSubmit) {
          Image(systemName: "paperplane.fill")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ColorToken.grayScale60.color : ColorToken.mainAccent.color)
        }
        .buttonStyle(.plain)
        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .frame(minHeight: 48)
      .padding(.horizontal, 14)
      .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(ColorToken.grayScale90.color.opacity(0.45), lineWidth: 1)
      }
    }
  }
}

private struct SharedEmptyCommentStateView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "message.circle")
        .font(.system(size: 28, weight: .regular))
        .foregroundStyle(ColorToken.grayScale60.color)

      Text("댓글이 없습니다")
        .font(TypographyToken.pretendardBody2.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale45.color)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 120)
  }
}

private struct SharedCommentAvatarView: View {
  let size: CGFloat

  var body: some View {
    Circle()
      .fill(ColorToken.brandBlackSprout.color)
      .frame(width: size, height: size)
      .overlay {
        Image(systemName: "person.fill")
          .font(.system(size: size * 0.45, weight: .regular))
          .foregroundStyle(ColorToken.grayScale60.color)
      }
  }
}

private extension String {
  var commentDisplayDate: String {
    if let date = try? Date(self, strategy: .iso8601) {
      return date.formatted(date: .numeric, time: .omitted)
    }
    return self
  }
}
