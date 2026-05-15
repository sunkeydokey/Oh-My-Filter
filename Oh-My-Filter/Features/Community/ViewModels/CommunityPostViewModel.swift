import Foundation
import Photos

@MainActor
@Observable
final class CommunityPostViewModel {
  var state: CommunityPostState

  private let service: any CommunityServicing
  private let mutationStore: CommunityPostMutationStore?
  private let likeCommitter: DebouncedBooleanCommitter
  private var pendingLikeRollback: (isLiked: Bool, likeCount: Int)?
  private let animeConverter: any AnimeGANConverting
  private let imageDataLoader: any AuthenticatedImageDataLoading
  private var animeConversionTask: Task<Void, Never>?
  private var animeConversionRequestID = UUID()

  init(
    mode: CommunityPostMode,
    preloadedImages: [PhotoPickerUploadSelection] = [],
    service: any CommunityServicing,
    mutationStore: CommunityPostMutationStore? = nil,
    animeConverter: any AnimeGANConverting = LiveAnimeGANConverter(),
    imageDataLoader: any AuthenticatedImageDataLoading = LiveAuthenticatedImageDataLoader(),
    likeDebounceDuration: Duration = .milliseconds(300)
  ) {
    var initialState = CommunityPostState(mode: mode)
    initialState.selectedImages = preloadedImages
    self.state = initialState
    self.service = service
    self.mutationStore = mutationStore
    self.animeConverter = animeConverter
    self.imageDataLoader = imageDataLoader
    self.likeCommitter = DebouncedBooleanCommitter(duration: likeDebounceDuration)
  }

  convenience init(
    mode: CommunityPostMode,
    preloadedImages: [PhotoPickerUploadSelection] = [],
    mutationStore: CommunityPostMutationStore? = nil
  ) {
    self.init(
      mode: mode,
      preloadedImages: preloadedImages,
      service: LiveCommunityService(),
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
      cancelLocalAnimeConversion()
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
      toggleLike()
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
    case .localSaveSucceededHandled:
      state.localSaveSucceeded = false
    case .detailSavePhaseHandled:
      state.detailSavePhase = .idle
    case let .errorPresented(message):
      state.errorMessage = message
    case .errorDismissed:
      state.errorMessage = nil

    // MARK: - Create/Edit: 이미지 저장
    case let .saveLocalImageTapped(selectionID):
      await saveLocalImage(selectionID: selectionID)

    // MARK: - Create/Edit: AnimeGAN
    case let .convertLocalImageToAnimeTapped(selectionID):
      startLocalAnimeConversion(selectionID: selectionID)

    case let .animeConversionProduced(selectionID, result):
      guard case .converting(selectionID) = state.localAnimeConversionState else { return }
      state.localAnimeConversionState = .awaitingChoice(selectionID: selectionID, result: result)

    case let .animeConversionFailed(selectionID, message):
      guard case .converting(selectionID) = state.localAnimeConversionState else { return }
      state.localAnimeConversionState = .failed(selectionID: selectionID, message: message)

    case let .animeConversionChoiceMade(useConverted):
      guard case let .awaitingChoice(selectionID, result) = state.localAnimeConversionState else { return }
      if useConverted { replaceLocalSelection(id: selectionID, with: result.convertedData) }
      state.localAnimeConversionState = .idle
      animeConversionTask = nil

    case .animeConversionDismissed:
      cancelLocalAnimeConversion()
      if case .converting = state.detailSavePhase { animeConversionTask?.cancel() }
      state.detailSavePhase = .idle

    // MARK: - Detail: 이미지 저장
    case let .saveRemoteImageTapped(url):
      await saveRemoteImage(url: url)

    case let .convertRemoteImageToAnimeTapped(url):
      await startRemoteAnimeConversionForSave(url: url)

    case let .animeConversionForSaveProduced(result):
      state.detailSavePhase = .awaitingAnimeChoice(result: result)

    case .saveAnimeResult:
      guard case let .awaitingAnimeChoice(result) = state.detailSavePhase else { return }
      await saveImageData(result.convertedData)
    }
  }

  // MARK: - Private: Create/Edit image save

  private func saveLocalImage(selectionID: UUID) async {
    guard let selection = state.selectedImages.first(where: { $0.id == selectionID }),
          selection.mediaKind == .image else { return }
    do {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        PHPhotoLibrary.shared().performChanges({
          let request = PHAssetCreationRequest.forAsset()
          request.addResource(with: .photo, data: selection.data, options: nil)
        }) { _, error in
          if let error { continuation.resume(throwing: error) }
          else { continuation.resume() }
        }
      }
      state.localSaveSucceeded = true
    } catch {
      state.errorMessage = "앨범 저장에 실패했습니다."
    }
  }

  // MARK: - Private: Create/Edit AnimeGAN

  private func startLocalAnimeConversion(selectionID: UUID) {
    guard state.localAnimeConversionState == .idle,
          let selection = state.selectedImages.first(where: { $0.id == selectionID }),
          selection.mediaKind == .image else { return }

    animeConversionTask?.cancel()
    let requestID = UUID()
    animeConversionRequestID = requestID
    state.localAnimeConversionState = .converting(selectionID: selectionID)

    animeConversionTask = Task { [animeConverter, data = selection.data, requestID] in
      do {
        let result = try await animeConverter.convert(imageData: data, maxPixelSize: 512)
        guard !Task.isCancelled, self.animeConversionRequestID == requestID else { return }
        await self.send(.animeConversionProduced(selectionID: selectionID, result: result))
      } catch is CancellationError {
      } catch {
        guard !Task.isCancelled, self.animeConversionRequestID == requestID else { return }
        await self.send(.animeConversionFailed(selectionID: selectionID, message: Self.animeErrorMessage(for: error)))
      }
    }
  }

  private func cancelLocalAnimeConversion() {
    animeConversionTask?.cancel()
    animeConversionRequestID = UUID()
    state.localAnimeConversionState = .idle
  }

  private func replaceLocalSelection(id: UUID, with convertedData: Data) {
    guard let index = state.selectedImages.firstIndex(where: { $0.id == id }) else { return }
    let original = state.selectedImages[index]
    state.selectedImages[index] = PhotoPickerUploadSelection(
      id: original.id,
      data: convertedData,
      fileName: original.fileName,
      mediaKind: .image,
      mimeType: "image/jpeg"
    )
  }

  // MARK: - Private: Detail remote image save

  private func saveRemoteImage(url: URL) async {
    guard state.detailSavePhase == .idle else { return }
    state.detailSavePhase = .saving
    do {
      let data = try await imageDataLoader.loadImageData(from: url)
      await saveImageData(data)
    } catch {
      state.detailSavePhase = .failed(message: "이미지를 불러올 수 없습니다.")
    }
  }

  private func startRemoteAnimeConversionForSave(url: URL) async {
    guard state.detailSavePhase == .idle else { return }
    state.detailSavePhase = .converting
    do {
      let data = try await imageDataLoader.loadImageData(from: url)
      animeConversionTask?.cancel()
      let requestID = UUID()
      animeConversionRequestID = requestID

      animeConversionTask = Task { [animeConverter, requestID] in
        do {
          let result = try await animeConverter.convert(imageData: data, maxPixelSize: 512)
          guard !Task.isCancelled, self.animeConversionRequestID == requestID else { return }
          await self.send(.animeConversionForSaveProduced(result: result))
        } catch is CancellationError {
        } catch {
          guard !Task.isCancelled, self.animeConversionRequestID == requestID else { return }
          self.state.detailSavePhase = .failed(message: Self.animeErrorMessage(for: error))
        }
      }
    } catch {
      state.detailSavePhase = .failed(message: "이미지를 불러올 수 없습니다.")
    }
  }

  private func saveImageData(_ data: Data) async {
    state.detailSavePhase = .saving
    do {
      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        PHPhotoLibrary.shared().performChanges({
          let request = PHAssetCreationRequest.forAsset()
          request.addResource(with: .photo, data: data, options: nil)
        }) { _, error in
          if let error { continuation.resume(throwing: error) }
          else { continuation.resume() }
        }
      }
      state.detailSavePhase = .saved
    } catch {
      state.detailSavePhase = .failed(message: "앨범 저장에 실패했습니다.")
    }
  }

  private nonisolated static func animeErrorMessage(for error: Error) -> String {
    if let e = error as? AnimeGANConversionError {
      switch e {
      case .invalidImageData: return "이미지를 불러올 수 없습니다."
      case .modelLoadFailed: return "모델을 불러올 수 없습니다."
      case .predictionFailed: return "변환에 실패했습니다."
      case .outputDecodingFailed: return "변환 결과를 처리할 수 없습니다."
      }
    }
    return "애니 변환에 실패했습니다. 잠시 후 다시 시도해주세요."
  }

  // MARK: - Private: existing logic

  private func loadIfNeeded() async {
    guard state.phase == .initial else { return }

    likeCommitter.cancel()
    pendingLikeRollback = nil
    state.phase = .loading
    do {
      async let currentUserID = try? service.loadCurrentUserID()
      let post: CommunityPost
      switch state.mode {
      case .create:
        state.currentUserID = await currentUserID
        state.phase = .loaded
        return
      case let .edit(postID), let .detail(postID):
        post = try await service.loadPostDetail(postID: postID)
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
        post = try await service.createPost(draft: state.draft, newImages: state.selectedImages)
        updateStateForCreatedPost(post)
        mutationStore?.publish(.created(post))
      case let .edit(postID):
        post = try await service.updatePost(postID: postID, draft: state.draft, newImages: state.selectedImages)
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

  private func toggleLike() {
    guard let post = state.post else { return }

    if pendingLikeRollback == nil {
      pendingLikeRollback = (post.isLiked, post.likeCount)
    }

    let targetStatus = post.isLiked == false
    state.post = post.replacingLike(
      isLiked: targetStatus,
      likeCount: max(0, post.likeCount + (targetStatus ? 1 : -1))
    )

    let postID = post.id
    likeCommitter.schedule(
      status: targetStatus,
      operation: { [service] status in
        try await service.toggleLike(postID: postID, status: status)
      },
      completion: { [weak self] result, requestedStatus in
        guard let self else { return }
        switch result {
        case let .success(confirmedStatus) where confirmedStatus == requestedStatus:
          pendingLikeRollback = nil
        case let .failure(error):
          rollbackLike()
          state.errorMessage = errorMessage(from: error)
        default:
          rollbackLike()
        }
      }
    )
  }

  private func rollbackLike() {
    guard let pendingLikeRollback,
          let post = state.post else {
      return
    }

    state.post = post.replacingLike(
      isLiked: pendingLikeRollback.isLiked,
      likeCount: pendingLikeRollback.likeCount
    )
    self.pendingLikeRollback = nil
  }

  private func deletePost() async {
    guard let postID = state.post?.id else { return }

    state.showsDeleteConfirmation = false

    do {
      try await service.deletePost(postID: postID)
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
      let created = try await service.createComment(
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
      let updated = try await service.updateComment(
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
      try await service.deleteComment(postID: post.id, commentID: target.commentID)
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

  func replacingLike(isLiked: Bool, likeCount: Int) -> CommunityPost {
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
      comments: comments,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}
