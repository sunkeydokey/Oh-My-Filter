import Foundation

@MainActor
@Observable
final class CommunityPostViewModel {
  var state: CommunityPostState

  private let useCase: any CommunityFeedUseCase
  private let mutationStore: CommunityPostMutationStore?

  init(
    mode: CommunityPostMode,
    preloadedImages: [PhotoPickerUploadSelection] = [],
    useCase: any CommunityFeedUseCase,
    mutationStore: CommunityPostMutationStore? = nil
  ) {
    var initialState = CommunityPostState(mode: mode)
    initialState.selectedImages = preloadedImages
    self.state = initialState
    self.useCase = useCase
    self.mutationStore = mutationStore
  }

  convenience init(
    mode: CommunityPostMode,
    preloadedImages: [PhotoPickerUploadSelection] = [],
    mutationStore: CommunityPostMutationStore? = nil
  ) {
    self.init(
      mode: mode,
      preloadedImages: preloadedImages,
      useCase: LiveCommunityFeedUseCase(),
      mutationStore: mutationStore
    )
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
    case .dismissDeleteConfirmation:
      state.showsDeleteConfirmation = false
    case let .commentTextChanged(text):
      updateCommentText(text)
    case .submitComment:
      await submitComment()
    case let .replyTapped(commentID):
      state.editingCommentTarget = nil
      state.commentText = ""
      state.replyingToCommentID = commentID
    case .cancelReply:
      state.replyingToCommentID = nil
    case let .editCommentTapped(commentID):
      startEditingComment(.comment(commentID: commentID))
    case let .editReplyTapped(parentCommentID, replyID):
      startEditingComment(.reply(parentCommentID: parentCommentID, replyID: replyID))
    case .cancelCommentEdit:
      state.editingCommentTarget = nil
      state.commentText = ""
    case let .deleteCommentTapped(commentID):
      state.pendingDeleteCommentTarget = .comment(commentID: commentID)
    case let .deleteReplyTapped(parentCommentID, replyID):
      state.pendingDeleteCommentTarget = .reply(parentCommentID: parentCommentID, replyID: replyID)
    case .deleteCommentConfirmed:
      await deleteComment()
    case .dismissDeleteCommentConfirmation:
      state.pendingDeleteCommentTarget = nil
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
        updateStateForCreatedPost(post)
        mutationStore?.publish(.created(post))
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
        mutationStore?.publish(.updated(post))
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

    state.showsDeleteConfirmation = false

    do {
      try await useCase.deletePost(postID: postID)
      mutationStore?.publish(.deleted(postID: postID))
      state.shouldDismiss = true
    } catch {
      state.errorMessage = errorMessage(from: error)
    }
  }

  private func updateStateForCreatedPost(_ post: CommunityPost) {
    state.mode = .detail(postID: post.id)
    state.phase = .loaded
    state.post = post
    state.originalDraft = CommunityPostDraft(
      category: post.category,
      title: post.title,
      content: post.content,
      existingFilePaths: post.imagePaths
    )
    state.draft = state.originalDraft
    state.selectedImages = []
    state.touchedFields = []
    state.expandedReplyCommentIDs = Set(post.comments.map(\.id))
  }

  private func submitComment() async {
    guard let post = state.post else { return }

    let content = state.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard content.isEmpty == false else { return }

    if let editingCommentTarget = state.editingCommentTarget {
      await updateComment(target: editingCommentTarget, content: content)
      return
    }

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

  private func startEditingComment(_ target: CommentEditTarget) {
    guard let content = state.post?.commentContent(for: target) else { return }
    state.replyingToCommentID = nil
    state.editingCommentTarget = target
    state.commentText = content
  }

  private func updateComment(target: CommentEditTarget, content: String) async {
    guard let post = state.post else { return }

    do {
      let updated = try await useCase.updateComment(
        postID: post.id,
        commentID: target.commentID,
        content: content
      )
      state.post = post.updating(comment: updated, target: target)
      state.editingCommentTarget = nil
      state.commentText = ""
    } catch {
      state.errorMessage = errorMessage(from: error)
    }
  }

  private func deleteComment() async {
    guard let post = state.post,
          let target = state.pendingDeleteCommentTarget else { return }

    state.pendingDeleteCommentTarget = nil

    do {
      try await useCase.deleteComment(postID: post.id, commentID: target.commentID)
      state.post = post.removingComment(target)
      if state.editingCommentTarget == target {
        state.editingCommentTarget = nil
        state.commentText = ""
      }
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
  func commentContent(for target: CommentEditTarget) -> String? {
    switch target {
    case let .comment(commentID):
      comments.first { $0.id == commentID }?.content
    case let .reply(parentCommentID, replyID):
      comments
        .first { $0.id == parentCommentID }?
        .replies
        .first { $0.id == replyID }?
        .content
    }
  }

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

  func updating(comment updated: CommunityReply, target: CommentEditTarget) -> CommunityPost {
    let updatedComments = comments.map { comment in
      switch target {
      case let .comment(commentID) where comment.id == commentID:
        CommunityComment(
          id: comment.id,
          content: updated.content,
          createdAt: updated.createdAt,
          creator: updated.creator,
          replies: comment.replies
        )
      case let .reply(parentCommentID, replyID) where comment.id == parentCommentID:
        CommunityComment(
          id: comment.id,
          content: comment.content,
          createdAt: comment.createdAt,
          creator: comment.creator,
          replies: comment.replies.map { reply in
            guard reply.id == replyID else { return reply }
            return CommunityReply(
              id: reply.id,
              content: updated.content,
              createdAt: updated.createdAt,
              creator: updated.creator
            )
          }
        )
      default:
        comment
      }
    }

    return replacingComments(updatedComments)
  }

  func removingComment(_ target: CommentEditTarget) -> CommunityPost {
    let updatedComments: [CommunityComment]
    switch target {
    case let .comment(commentID):
      updatedComments = comments.filter { $0.id != commentID }
    case let .reply(parentCommentID, replyID):
      updatedComments = comments.map { comment in
        guard comment.id == parentCommentID else { return comment }
        return CommunityComment(
          id: comment.id,
          content: comment.content,
          createdAt: comment.createdAt,
          creator: comment.creator,
          replies: comment.replies.filter { $0.id != replyID }
        )
      }
    }

    return replacingComments(updatedComments)
  }

  func replacingComments(_ updatedComments: [CommunityComment]) -> CommunityPost {
    CommunityPost(
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
