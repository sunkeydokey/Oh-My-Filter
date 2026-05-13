import Foundation

nonisolated enum CommunityPostMode: Equatable, Sendable {
  case create
  case edit(postID: String)
  case detail(postID: String)
}

nonisolated enum CommunityPostSubmitPhase: Equatable, Sendable {
  case idle
  case submitting
}

// Create/Edit: 어느 타일에서 AnimeGAN 변환이 진행 중인지 추적
nonisolated enum CommunityAnimeConversionState: Sendable {
  case idle
  case converting(selectionID: UUID)
  case awaitingChoice(selectionID: UUID, result: AnimeConversionResult)
  case failed(selectionID: UUID, message: String)
}

extension CommunityAnimeConversionState: Equatable {
  nonisolated static func == (lhs: CommunityAnimeConversionState, rhs: CommunityAnimeConversionState) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle): return true
    case let (.converting(l), .converting(r)): return l == r
    case let (.awaitingChoice(lID, lResult), .awaitingChoice(rID, rResult)): return lID == rID && lResult == rResult
    case let (.failed(lID, lMsg), .failed(rID, rMsg)): return lID == rID && lMsg == rMsg
    default: return false
    }
  }
}

// Detail: 이미지 저장/AnimeGAN 변환 저장 흐름
nonisolated enum CommunityDetailSavePhase: Sendable {
  case idle
  case converting
  case awaitingAnimeChoice(result: AnimeConversionResult)
  case saving
  case saved
  case failed(message: String)
}

extension CommunityDetailSavePhase: Equatable {
  nonisolated static func == (lhs: CommunityDetailSavePhase, rhs: CommunityDetailSavePhase) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle), (.converting, .converting), (.saving, .saving), (.saved, .saved): return true
    case let (.awaitingAnimeChoice(l), .awaitingAnimeChoice(r)): return l == r
    case let (.failed(l), .failed(r)): return l == r
    default: return false
    }
  }
}

nonisolated struct CommunityPostState: Equatable, Sendable {
  var mode: CommunityPostMode
  var phase: CommunityLoadPhase
  var post: CommunityPost?
  var draft = CommunityPostDraft()
  var originalDraft = CommunityPostDraft()
  var selectedImages: [PhotoPickerUploadSelection] = []
  var touchedFields: Set<CommunityPostField> = []
  var submitPhase: CommunityPostSubmitPhase = .idle
  var errorMessage: String?
  var currentUserID: String?
  var expandedReplyCommentIDs: Set<String> = []
  var commentText = ""
  var replyingToCommentID: String?
  var editingCommentTarget: CommentEditTarget?
  var pendingDeleteCommentTarget: CommentEditTarget?
  var route: CommunityRoute?
  var shouldDismiss = false
  var showsDiscardConfirmation = false
  var showsDeleteConfirmation = false

  // Create/Edit: AnimeGAN 변환 상태
  var localAnimeConversionState: CommunityAnimeConversionState = .idle
  // Create/Edit: 로컬 이미지 저장 성공 트리거
  var localSaveSucceeded = false

  // Detail: 이미지 저장/변환 저장 흐름
  var detailSavePhase: CommunityDetailSavePhase = .idle

  init(mode: CommunityPostMode) {
    self.mode = mode
    self.phase = mode == .create ? .loaded : .initial
  }

  var isDetail: Bool {
    if case .detail = mode {
      return true
    }
    return false
  }

  var navigationTitle: String {
    switch mode {
    case .create:
      "게시글 작성"
    case .edit:
      "게시글 수정"
    case .detail:
      "게시글"
    }
  }

  var primaryActionTitle: String {
    switch mode {
    case .create:
      "등록"
    case .edit:
      "수정 완료"
    case .detail:
      ""
    }
  }

  var isMine: Bool {
    guard let currentUserID, let post else { return false }
    return post.creator.id == currentUserID
  }

  var isOwner: Bool { isMine }

  var isDirty: Bool {
    draft != originalDraft || selectedImages.isEmpty == false
  }

  var canSubmit: Bool {
    submitPhase == .idle
      && categoryError == nil
      && titleError == nil
      && contentError == nil
      && isRequiredInputFilled
  }

  var isRequiredInputFilled: Bool {
    normalized(draft.category).isEmpty == false
      && normalized(draft.title).isEmpty == false
      && normalized(draft.content).isEmpty == false
  }

  var categoryError: String? {
    let value = normalized(draft.category)
    if value.isEmpty {
      return "카테고리를 입력해주세요"
    }

    if value.contains(where: Self.forbiddenCategoryCharacters.contains) {
      return "사용할 수 없는 문자가 포함되어 있습니다"
    }

    return nil
  }

  var titleError: String? {
    normalized(draft.title).isEmpty ? "제목을 입력해주세요" : nil
  }

  var contentError: String? {
    let value = normalized(draft.content)
    if value.isEmpty {
      return "내용을 입력해주세요"
    }

    if draft.content.count > Self.contentLimit {
      return "내용은 \(Self.contentLimit.formatted(.number))자까지 입력할 수 있습니다"
    }

    return nil
  }

  func visibleError(for field: CommunityPostField) -> String? {
    guard touchedFields.contains(field) else { return nil }

    switch field {
    case .category:
      return categoryError
    case .title:
      return titleError
    case .content:
      return contentError
    }
  }

  func normalized(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  // MARK: - AnimeGAN computed properties

  var isLocalAnimeSheetPresented: Bool {
    localAnimeConversionState != .idle
  }

  var localAnimePreviewSheetState: AnimeConversionState {
    switch localAnimeConversionState {
    case .idle: .idle
    case .converting: .converting
    case let .awaitingChoice(_, result): .awaitingChoice(result: result)
    case let .failed(_, message): .failed(message: message)
    }
  }

  var convertingLocalSelectionID: UUID? {
    if case let .converting(id) = localAnimeConversionState { return id }
    return nil
  }

  var isDetailAnimeSheetPresented: Bool {
    switch detailSavePhase {
    case .converting, .awaitingAnimeChoice: return true
    default: return false
    }
  }

  var detailAnimePreviewSheetState: AnimeConversionState {
    switch detailSavePhase {
    case .converting: .converting
    case let .awaitingAnimeChoice(result): .awaitingChoice(result: result)
    default: .idle
    }
  }

  static let contentLimit = 2_000
  private static let forbiddenCategoryCharacters = Set(".,?*-+@^${}()|[]\\")
}
