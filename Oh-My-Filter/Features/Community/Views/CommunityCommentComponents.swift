import SwiftUI

struct CommunityCommentSectionView: View {
  let comments: [CommunityComment]
  let expandedReplyCommentIDs: Set<String>
  let replyingToCommentID: String?
  let commentText: String
  let onTextChanged: (String) -> Void
  let onSubmit: () -> Void
  let onReply: (String) -> Void
  let onCancelReply: () -> Void
  let onToggleReplies: (String) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if comments.isEmpty {
        CommunityEmptyCommentStateView()
      } else {
        Text("댓글")
          .font(TypographyToken.pretendardBody1.font.weight(.bold))
          .foregroundStyle(ColorToken.grayScale30.color)

        LazyVStack(alignment: .leading, spacing: 0) {
          ForEach(comments) { comment in
            CommunityCommentRowView(
              comment: comment,
              isExpanded: expandedReplyCommentIDs.contains(comment.id),
              onReply: { onReply(comment.id) },
              onToggleReplies: { onToggleReplies(comment.id) }
            )
          }
        }
      }

      CommunityCommentComposerView(
        text: commentText,
        replyingToCommentID: replyingToCommentID,
        onTextChanged: onTextChanged,
        onSubmit: onSubmit,
        onCancelReply: onCancelReply
      )
    }
  }
}

struct CommunityCommentRowView: View {
  let comment: CommunityComment
  let isExpanded: Bool
  let onReply: () -> Void
  let onToggleReplies: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .top, spacing: 10) {
        CommunityCommentAvatarView(size: 32)

        VStack(alignment: .leading, spacing: 5) {
          Text(comment.creator.nick)
            .font(TypographyToken.pretendardCaption1.font.weight(.bold))
            .foregroundStyle(ColorToken.grayScale0.color)

          Text(comment.content)
            .font(TypographyToken.pretendardCaption1.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)

          CommunityCommentActionRowView(
            timestamp: comment.createdAt.communityDisplayDate,
            replyTitle: "답글 달기",
            onReply: onReply
          )
        }
      }
      .padding(.vertical, 12)

      if comment.replies.isEmpty == false {
        CommunityReplyGroupView(
          replies: comment.replies,
          isExpanded: isExpanded,
          onToggle: onToggleReplies
        )
      }

      Divider()
        .overlay(ColorToken.grayScale90.color.opacity(0.45))
    }
  }
}

struct CommunityReplyGroupView: View {
  let replies: [CommunityReply]
  let isExpanded: Bool
  let onToggle: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button(isExpanded ? "답글 숨기기" : "답글 보기", action: onToggle)
        .font(TypographyToken.pretendardCaption2.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale60.color)
        .buttonStyle(.plain)

      if isExpanded {
        ForEach(replies) { reply in
          CommunityReplyRowView(reply: reply)
        }
      }
    }
    .padding(.leading, 42)
    .padding(.bottom, 8)
  }
}

struct CommunityReplyRowView: View {
  let reply: CommunityReply

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      CommunityCommentAvatarView(size: 24)

      VStack(alignment: .leading, spacing: 5) {
        Text(reply.creator.nick)
          .font(TypographyToken.pretendardCaption2.font.weight(.bold))
          .foregroundStyle(ColorToken.grayScale0.color)

        Text(reply.content)
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

struct CommunityCommentActionRowView: View {
  let timestamp: String
  let replyTitle: String
  let onReply: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Text(timestamp)
        .font(TypographyToken.pretendardCaption2.font)
        .foregroundStyle(ColorToken.grayScale60.color)

      Button(replyTitle, action: onReply)
        .font(TypographyToken.pretendardCaption2.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale60.color)
        .buttonStyle(.plain)
    }
  }
}

struct CommunityCommentComposerView: View {
  let text: String
  let replyingToCommentID: String?
  let onTextChanged: (String) -> Void
  let onSubmit: () -> Void
  let onCancelReply: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if replyingToCommentID != nil {
        HStack(spacing: 8) {
          Text("답글")
            .font(TypographyToken.pretendardCaption2.font.weight(.bold))
            .foregroundStyle(ColorToken.sesacFilterBrightTurquoise.color)

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
            .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ColorToken.grayScale60.color : ColorToken.sesacFilterBrightTurquoise.color)
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

struct CommunityEmptyCommentStateView: View {
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

private struct CommunityCommentAvatarView: View {
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
  var communityDisplayDate: String {
    if let date = try? Date(self, strategy: .iso8601) {
      return date.formatted(date: .numeric, time: .omitted)
    }
    return self
  }
}
