import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class FilterDetailViewModel {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "FilterDetailViewModel"
  )

  var state = FilterDetailState()

  private let filterID: String
  private let useCase: any FilterDetailUseCase
  private let orderCreateUseCase: any OrderCreateUseCase
  private let paymentValidationUseCase: any PaymentValidationUseCase
  private let renderer: any ImageFilterRendering
  private let imageDataLoader: any AuthenticatedImageDataLoading

  init(
    filterID: String,
    useCase: any FilterDetailUseCase,
    orderCreateUseCase: (any OrderCreateUseCase)? = nil,
    paymentValidationUseCase: (any PaymentValidationUseCase)? = nil,
    renderer: any ImageFilterRendering,
    imageDataLoader: any AuthenticatedImageDataLoading = LiveAuthenticatedImageDataLoader()
  ) {
    self.filterID = filterID
    self.useCase = useCase
    self.orderCreateUseCase = orderCreateUseCase ?? LiveOrderCreateUseCase()
    self.paymentValidationUseCase = paymentValidationUseCase ?? LivePaymentValidationUseCase()
    self.renderer = renderer
    self.imageDataLoader = imageDataLoader
  }

  convenience init(
    filterID: String,
    service: any FilterDetailServicing,
    renderer: any ImageFilterRendering = CoreImageFilterRenderer()
  ) {
    self.init(
      filterID: filterID,
      useCase: LiveFilterDetailUseCase(service: service),
      orderCreateUseCase: LiveOrderCreateUseCase(),
      paymentValidationUseCase: LivePaymentValidationUseCase(),
      renderer: renderer
    )
  }

  convenience init(filterID: String) {
    self.init(
      filterID: filterID,
      useCase: LiveFilterDetailUseCase(),
      orderCreateUseCase: LiveOrderCreateUseCase(),
      paymentValidationUseCase: LivePaymentValidationUseCase(),
      renderer: CoreImageFilterRenderer()
    )
  }

  func send(_ action: FilterDetailAction) async {
    switch action {
    case .task, .retry:
      await load()
    case .tapDownload:
      await startPayment()
    case let .paymentResponseReceived(response):
      await handlePaymentResponse(response)
    case .dismissPaymentSheet:
      state.paymentRequest = nil
    case let .commentTextChanged(text):
      state.commentText = text
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
    case .tapEdit:
      await routeToUpdate()
    case .routeHandled:
      state.route = nil
    case .dismissAlert, .confirmAlert:
      state.alert = nil
    }
  }

  private func load() async {
    let previous = state.detail
    state.phase = .loading(previous: previous)

    do {
      async let detailResponse = useCase.loadFilterDetail(filterID: filterID)
      async let currentUserIDResponse = useCase.loadCurrentUserID()
      let detail = try await detailResponse
      state.currentUserID = try? await currentUserIDResponse
      state.expandedReplyCommentIDs = Set(detail.comments.map(\.id))
      state.phase = .loaded(detail, .rendering)
      await renderPreview(for: detail)
    } catch is CancellationError {
      state.phase = previous.map { .loaded($0, .fallback(originalImageURL: $0.originalImageURL, filteredImageURL: $0.fallbackFilteredImageURL)) } ?? .idle
    } catch {
      state.phase = .failed(message: Self.fallbackMessage(for: error), previous: previous)
      Self.logger.error("❌ [FilterDetailViewModel] load failed \(String(describing: error), privacy: .public)")
    }
  }

  private func renderPreview(for detail: FilterDetail) async {
    guard let originalImageURL = detail.originalImageURL else {
      state.phase = .loaded(detail, .fallback(originalImageURL: nil, filteredImageURL: detail.fallbackFilteredImageURL))
      return
    }

    do {
      let renderedImages = try await renderer.render(
        originalImageURL: originalImageURL,
        filterValues: detail.filterValues
      )
      state.phase = .loaded(detail, .rendered(renderedImages))
    } catch is CancellationError {
      state.phase = .loaded(detail, .fallback(originalImageURL: detail.originalImageURL, filteredImageURL: detail.fallbackFilteredImageURL))
    } catch {
      state.phase = .loaded(detail, .fallback(originalImageURL: detail.originalImageURL, filteredImageURL: detail.fallbackFilteredImageURL))
      Self.logger.error("❌ [FilterDetailViewModel] render failed \(String(describing: error), privacy: .public)")
    }
  }

  private func startPayment() async {
    guard state.isPaymentProcessing == false,
          state.paymentRequest == nil,
          let detail = state.detail else {
      return
    }

    guard detail.isDownloaded == false else {
      return
    }

    state.isPaymentProcessing = true
    do {
      let order = try await orderCreateUseCase.createOrder(
        filterID: detail.id,
        totalPrice: detail.price
      )
      state.paymentRequest = PortonePaymentRequest(
        detail: detail,
        merchantUID: order.orderCode
      )
      state.isPaymentProcessing = false
    } catch is CancellationError {
      state.isPaymentProcessing = false
    } catch {
      state.isPaymentProcessing = false
      showPaymentAlert(message: Self.paymentMessage(for: error))
      Self.logger.error("❌ [FilterDetailViewModel] order creation failed \(String(describing: error), privacy: .public)")
    }
  }

  private func handlePaymentResponse(_ response: PortonePaymentResponse?) async {
    state.paymentRequest = nil

    guard let response else {
      return
    }

    guard response.success else {
      showPaymentAlert(message: response.errorMessage ?? "결제가 완료되지 않았습니다.")
      return
    }

    guard let impUID = response.impUID, impUID.isEmpty == false else {
      showPaymentAlert(message: "결제 승인 정보를 확인할 수 없습니다.")
      return
    }

    state.isPaymentProcessing = true
    do {
      try await paymentValidationUseCase.validatePayment(impUID: impUID)
      await load()
      state.isPaymentProcessing = false
    } catch is CancellationError {
      state.isPaymentProcessing = false
    } catch {
      state.isPaymentProcessing = false
      showPaymentAlert(message: Self.paymentMessage(for: error))
      Self.logger.error("❌ [FilterDetailViewModel] payment validation failed \(String(describing: error), privacy: .public)")
    }
  }

  private func submitComment() async {
    guard case let .loaded(detail, previewState) = state.phase else { return }

    let content = state.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard content.isEmpty == false else { return }

    do {
      let created = try await useCase.createComment(
        filterID: filterID,
        parentCommentID: state.replyingToCommentID,
        content: content
      )
      state.phase = .loaded(
        detail.appending(createdComment: created, parentCommentID: state.replyingToCommentID),
        previewState
      )
      if let replyingToCommentID = state.replyingToCommentID {
        state.expandedReplyCommentIDs.insert(replyingToCommentID)
      }
      state.commentText = ""
      state.replyingToCommentID = nil
    } catch {
      state.alert = FilterDetailAlert(
        title: "댓글",
        message: Self.fallbackMessage(for: error),
        cancelTitle: "취소",
        confirmTitle: "확인"
      )
    }
  }

  private func routeToUpdate() async {
    guard state.isMine, let detail = state.detail else { return }

    do {
      state.route = .update(try await updateDraft(from: detail))
    } catch is CancellationError {
    } catch {
      state.alert = FilterDetailAlert(
        title: "필터 수정",
        message: "수정 화면을 준비할 수 없습니다. 잠시 후 다시 시도해 주세요.",
        cancelTitle: "취소",
        confirmTitle: "확인"
      )
    }
  }

  private func updateDraft(from detail: FilterDetail) async throws -> FilterMakeDraft {
    let representativeImageData: Data?
    if let originalImageURL = detail.originalImageURL {
      representativeImageData = try await imageDataLoader.loadImageData(from: originalImageURL)
    } else {
      representativeImageData = nil
    }

    return FilterMakeDraft(
      filterID: detail.id,
      name: detail.title,
      category: detail.category.flatMap(FilterMakeCategory.init(rawValue:)) ?? .portrait,
      introduction: detail.introduction ?? detail.description,
      price: detail.price,
      representativeImageData: representativeImageData,
      photoMetadata: detail.metadata,
      filterParameterValues: FilterEditParameter.filterParameterValues(from: detail.filterValues)
    )
  }

  private func showPaymentAlert(message: String) {
    state.alert = FilterDetailAlert(
      title: "필터 결제",
      message: message,
      cancelTitle: "취소",
      confirmTitle: "확인"
    )
  }

  private static func fallbackMessage(for error: Error) -> String {
    if let serviceError = error as? FilterDetailServiceError,
       let message = serviceError.errorDescription {
      return message
    }

    return FilterDetailServiceError.serverError.errorDescription ?? "잠시 후 다시 시도해 주세요."
  }

  private static func paymentMessage(for error: Error) -> String {
    if let orderError = error as? OrderServiceError,
       let message = orderError.errorDescription {
      return message
    }

    if let paymentError = error as? PaymentServiceError,
       let message = paymentError.errorDescription {
      return message
    }

    return "결제를 처리할 수 없습니다. 잠시 후 다시 시도해 주세요."
  }
}

private extension FilterDetail {
  func appending(createdComment: CommentReply, parentCommentID: String?) -> FilterDetail {
    let updatedComments: [Comment]
    if let parentCommentID {
      updatedComments = comments.map { comment in
        guard comment.id == parentCommentID else { return comment }
        return Comment(
          id: comment.id,
          content: comment.content,
          createdAt: comment.createdAt,
          creator: comment.creator,
          replies: comment.replies + [createdComment]
        )
      }
    } else {
      updatedComments = comments + [
        Comment(
          id: createdComment.id,
          content: createdComment.content,
          createdAt: createdComment.createdAt,
          creator: createdComment.creator,
          replies: []
        ),
      ]
    }

    return FilterDetail(
      id: id,
      title: title,
      category: category,
      introduction: introduction,
      description: description,
      originalImageURL: originalImageURL,
      fallbackFilteredImageURL: fallbackFilteredImageURL,
      creator: creator,
      metadata: metadata,
      filterValues: filterValues,
      comments: updatedComments,
      isDownloaded: isDownloaded,
      isLiked: isLiked,
      likeCount: likeCount,
      buyerCount: buyerCount,
      price: price,
      hashTags: hashTags,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}
