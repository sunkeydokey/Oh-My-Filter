import SwiftUI

struct FilterDetailCommentsView: View {
  let comments: [FilterDetailComment]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      MainSectionHeaderView(title: "댓글")

      if comments.isEmpty {
        Text("아직 댓글이 없습니다.")
          .font(TypographyToken.pretendardBody3.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(14)
          .background(ColorToken.brandDeepSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
      } else {
        ForEach(comments) { comment in
          FilterDetailCommentView(comment: comment)
        }
      }
    }
  }
}

struct FilterDetailCommentView: View {
  let comment: FilterDetailComment

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      FilterDetailCommentBodyView(user: comment.user, content: comment.content)

      ForEach(comment.replies) { reply in
        FilterDetailCommentBodyView(user: reply.user, content: reply.content)
          .padding(.leading, 18)
      }
    }
    .padding(14)
    .background(ColorToken.brandDeepSprout.color, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}

struct FilterDetailCommentBodyView: View {
  let user: FilterDetailCommentUser
  let content: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(user.nick)
        .font(TypographyToken.pretendardCaption1.font)
        .bold()
        .foregroundStyle(ColorToken.grayScale0.color)

      Text(content)
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale45.color)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}
