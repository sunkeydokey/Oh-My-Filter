import Foundation

@MainActor
@Observable
final class CommunityPostViewModel {
  var state: CommunityPostState

  private let useCase: any CommunityFeedUseCase

  init(
    mode: CommunityPostMode,
    useCase: any CommunityFeedUseCase
  ) {
    self.state = CommunityPostState(mode: mode)
    self.useCase = useCase
  }

  convenience init(mode: CommunityPostMode) {
    self.init(mode: mode, useCase: LiveCommunityFeedUseCase())
  }

  func updateCategory(_ category: String) {
    state.draft.category = category
  }

  func updateTitle(_ title: String) {
    state.draft.title = title
  }

  func updateContent(_ content: String) {
    state.draft.content = content
  }

  func updateCommentText(_ text: String) {
    state.commentText = text
  }

  func markFieldFocused(_ field: CommunityPostField) {
    state.touchedFields.insert(field)
  }

  func send(_ action: CommunityPostAction) async {
    switch action {
    case .task:
      await loadIfNeeded()
    case .retry:
      state.phase = .initial
      await loadIfNeeded()
    case let .categoryChanged(category):
      updateCategory(category)
    case let .titleChanged(title):
      updateTitle(title)
    case let .contentChanged(content):
      updateContent(content)
    case let .imageSelectionChanged(images):
      state.selectedImages = images
    case let .removeExistingImage(path):
      state.draft.existingFilePaths.removeAll { $0 == path }
    case let .fieldFocused(field):
      markFieldFocused(field)
    case .submit:
      await submit()
    case .cancelTapped:
      cancel()
    case .discardChangesConfirmed:
      state.showsDiscardConfirmation = false
      state.shouldDismiss = true
    case .likeTapped:
      await toggleLike()
    case .editTapped:
      if let postID = state.post?.id {
        state.route = .postEdit(postID: postID)
      }
    case .deleteTapped:
      state.showsDeleteConfirmation = true
    case .deleteConfirmed:
      await deletePost()
    case let .commentTextChanged(text):
      updateCommentText(text)
    case .submitComment:
      await submitComment()
    case let .replyTapped(commentID):
      state.replyingToCommentID = commentID
    case .cancelReply:
      state.replyingToCommentID = nil
    case let .toggleReplies(commentID):
      if state.expandedReplyCommentIDs.contains(commentID) {
        state.expandedReplyCommentIDs.remove(commentID)
      } else {
        state.expandedReplyCommentIDs.insert(commentID)
      }
    case .routeHandled:
      state.route = nil
    case .dismissHandled:
      state.shouldDismiss = false
    }
  }

  private func loadIfNeeded() async {
    guard state.phase == .initial else { return }

    state.phase = .loading
    do {
      async let currentUserID = try? useCase.loadCurrentUserID()
      let post: CommunityPost
      switch state.mode {
      case .create:
        state.currentUserID = await currentUserID
        state.phase = .loaded
        return
      case let .edit(postID), let .detail(postID):
        post = try await useCase.loadPostDetail(postID: postID)
      }

      state.currentUserID = await currentUserID
      state.post = post
      state.draft = CommunityPostDraft(
        category: post.category,
        title: post.title,
        content: post.content,
        existingFilePaths: post.imagePaths
      )
      state.originalDraft = state.draft
      state.expandedReplyCommentIDs = Set(post.comments.map(\.id))
      state.phase = .loaded
    } catch {
      state.errorMessage = errorMessage(from: error)
      state.phase = .error(message: state.errorMessage ?? "잠시 후 다시 시도해 주세요.")
    }
  }

  private func submit() async {
    state.touchedFields = [.category, .title, .content]
    guard state.canSubmit else { return }

    state.submitPhase = .submitting
    do {
      let post: CommunityPost
      switch state.mode {
      case .create:
        post = try await useCase.createPost(draft: state.draft, newImages: state.selectedImages)
        state.route = .postDetail(postID: post.id)
      case let .edit(postID):
        post = try await useCase.updatePost(postID: postID, draft: state.draft, newImages: state.selectedImages)
        state.post = post
        state.originalDraft = CommunityPostDraft(
          category: post.category,
          title: post.title,
          content: post.content,
          existingFilePaths: post.imagePaths
        )
        state.draft = state.originalDraft
        state.selectedImages = []
        state.shouldDismiss = true
      case .detail:
        break
      }
    } catch {
      state.errorMessage = errorMessage(from: error)
    }
    state.submitPhase = .idle
  }

  private func cancel() {
    if case .edit = state.mode, state.isDirty {
      state.showsDiscardConfirmation = true
      return
    }

    state.shouldDismiss = true
  }

  private func toggleLike() async {
    guard let post = state.post else { return }

    let targetStatus = post.isLiked == false
    let optimisticPost = CommunityPost(
      id: post.id,
      category: post.category,
      title: post.title,
      content: post.content,
      creator: post.creator,
      attachments: post.attachments,
      imagePaths: post.imagePaths,
      isLiked: targetStatus,
      likeCount: max(0, post.likeCount + (targetStatus ? 1 : -1)),
      comments: post.comments,
      createdAt: post.createdAt,
      updatedAt: post.updatedAt
    )
    state.post = optimisticPost

    do {
      let confirmedStatus = try await useCase.toggleLike(postID: post.id, status: targetStatus)
      if confirmedStatus != targetStatus {
        state.post = post
      }
    } catch {
      state.post = post
      state.errorMessage = errorMessage(from: error)
    }
  }

  private func deletePost() async {
    guard let postID = state.post?.id else { return }

    do {
      try await useCase.deletePost(postID: postID)
      state.showsDeleteConfirmation = false
      state.shouldDismiss = true
    } catch {
      state.errorMessage = errorMessage(from: error)
    }
  }

  private func submitComment() async {
    guard let post = state.post else { return }

    let content = state.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard content.isEmpty == false else { return }

    do {
      let created = try await useCase.createComment(
        postID: post.id,
        parentCommentID: state.replyingToCommentID,
        content: content
      )
      state.post = post.appending(createdComment: created, parentCommentID: state.replyingToCommentID)
      if let replyingToCommentID = state.replyingToCommentID {
        state.expandedReplyCommentIDs.insert(replyingToCommentID)
      }
      state.commentText = ""
      state.replyingToCommentID = nil
    } catch {
      state.errorMessage = errorMessage(from: error)
    }
  }

  private func errorMessage(from error: Error) -> String {
    if let serviceError = error as? CommunityServiceError {
      return serviceError.errorDescription ?? "잠시 후 다시 시도해 주세요."
    }
    return "잠시 후 다시 시도해 주세요."
  }
}

private extension CommunityPost {
  func appending(createdComment: CommunityReply, parentCommentID: String?) -> CommunityPost {
    let updatedComments: [CommunityComment]
    if let parentCommentID {
      updatedComments = comments.map { comment in
        guard comment.id == parentCommentID else { return comment }
        return CommunityComment(
          id: comment.id,
          content: comment.content,
          createdAt: comment.createdAt,
          creator: comment.creator,
          replies: comment.replies + [createdComment]
        )
      }
    } else {
      updatedComments = comments + [
        CommunityComment(
          id: createdComment.id,
          content: createdComment.content,
          createdAt: createdComment.createdAt,
          creator: createdComment.creator,
          replies: []
        ),
      ]
    }

    return CommunityPost(
      id: id,
      category: category,
      title: title,
      content: content,
      creator: creator,
      attachments: attachments,
      imagePaths: imagePaths,
      isLiked: isLiked,
      likeCount: likeCount,
      comments: updatedComments,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}
