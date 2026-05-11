import CoreGraphics
import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct FilterDetailViewModelTests {
  @Test("initial load success stores rendered preview")
  func initialLoadSuccessStoresRenderedPreview() async throws {
    let service = MockFilterDetailService(result: .success(.sample))
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", service: service, renderer: renderer)

    await viewModel.send(.task)

    guard case let .loaded(detail, previewState) = viewModel.state.phase else {
      Issue.record("Expected loaded state")
      return
    }

    #expect(detail.id == "filter-123")
    guard case .rendered = previewState else {
      Issue.record("Expected rendered preview")
      return
    }
  }

  @Test("load failure stores message")
  func loadFailureStoresMessage() async {
    let service = MockFilterDetailService(result: .failure(FilterDetailServiceError.transport))
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", service: service, renderer: renderer)

    await viewModel.send(.task)

    guard case let .failed(message, previous) = viewModel.state.phase else {
      Issue.record("Expected failed state")
      return
    }

    #expect(message == "네트워크 상태를 확인한 뒤 다시 시도해 주세요.")
    #expect(previous == nil)
  }

  @Test("render failure uses fallback URLs")
  func renderFailureUsesFallbackURLs() async {
    let service = MockFilterDetailService(result: .success(.sample))
    let renderer = MockImageFilterRenderer(result: .failure(ImageFilterRenderingError.renderFailed))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", service: service, renderer: renderer)

    await viewModel.send(.task)

    guard case let .loaded(_, previewState) = viewModel.state.phase,
          case let .fallback(originalImageURL, filteredImageURL) = previewState else {
      Issue.record("Expected fallback preview")
      return
    }

    #expect(originalImageURL?.absoluteString == "https://example.com/original.jpg")
    #expect(filteredImageURL?.absoluteString == "https://example.com/filtered.jpg")
  }

  @Test("payment alert can be dismissed by cancel and confirm")
  func paymentAlertCanBeDismissed() async {
    let viewModel = await paymentReadyViewModel()

    await viewModel.send(.paymentResponseReceived(.failure))
    #expect(viewModel.state.alert?.confirmTitle == "확인")

    await viewModel.send(.dismissAlert)
    #expect(viewModel.state.alert == nil)

    await viewModel.send(.paymentResponseReceived(.failure))
    await viewModel.send(.confirmAlert)
    #expect(viewModel.state.alert == nil)
  }

  @Test("tap download creates order and opens payment request for undownloaded filter")
  func tapDownloadCreatesOrderAndPaymentRequest() async {
    let service = MockFilterDetailService(result: .success(.undownloadedSample))
    let purchaseUseCase = MockFilterPurchaseUseCase()
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(
      filterID: "filter-123",
      service: service,
      purchaseUseCase: purchaseUseCase,
      renderer: renderer
    )

    await viewModel.send(.task)
    await viewModel.send(.tapDownload)

    #expect(await purchaseUseCase.requestedDetailIDs == ["filter-123"])
    #expect(viewModel.state.paymentRequest?.merchantUID == "D123456")
    #expect(viewModel.state.paymentRequest?.amount == "2000")
  }

  @Test("nil payment response is treated as user cancellation")
  func nilPaymentResponseClosesSheetOnly() async {
    let viewModel = await paymentReadyViewModel()

    await viewModel.send(.paymentResponseReceived(nil))

    #expect(viewModel.state.paymentRequest == nil)
    #expect(viewModel.state.alert == nil)
  }

  @Test("failed payment response shows alert")
  func failedPaymentResponseShowsAlert() async {
    let viewModel = await paymentReadyViewModel()

    await viewModel.send(.paymentResponseReceived(.failure))

    #expect(viewModel.state.paymentRequest == nil)
    #expect(viewModel.state.alert?.message == "카드 승인 실패")
  }

  @Test("successful payment response without imp uid shows alert")
  func successfulPaymentWithoutImpUIDShowsAlert() async {
    let viewModel = await paymentReadyViewModel()

    await viewModel.send(.paymentResponseReceived(.success(impUID: nil)))

    #expect(viewModel.state.alert?.message == "결제 승인 정보를 확인할 수 없습니다.")
  }

  @Test("successful payment validates with server and reloads detail")
  func successfulPaymentValidatesAndReloadsDetail() async {
    let service = SequencedFilterDetailService(results: [
      .success(.undownloadedSample),
      .success(.sample),
    ])
    let purchaseUseCase = MockFilterPurchaseUseCase()
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(
      filterID: "filter-123",
      service: service,
      purchaseUseCase: purchaseUseCase,
      renderer: renderer
    )

    await viewModel.send(.task)
    await viewModel.send(.tapDownload)
    await viewModel.send(.paymentResponseReceived(.success(impUID: "imp-123")))

    #expect(await purchaseUseCase.validatedResponses == [.success(impUID: "imp-123")])
    #expect(viewModel.state.detail?.isDownloaded == true)
  }

  @Test("payment validation failure shows alert and keeps existing detail")
  func paymentValidationFailureShowsAlertAndKeepsDetail() async {
    let viewModel = await paymentReadyViewModel(
      paymentResult: .failure(PaymentServiceError.validationFailed)
    )

    await viewModel.send(.paymentResponseReceived(.success(impUID: "imp-123")))

    #expect(viewModel.state.detail?.isDownloaded == false)
    #expect(viewModel.state.alert?.message == "결제 검증에 실패했습니다. 잠시 후 다시 시도해 주세요.")
  }

  @Test("reply submit appends filter reply and expands group")
  func replySubmitAppendsFilterReply() async {
    let service = MockFilterDetailService(result: .success(.sampleWithComment))
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", service: service, renderer: renderer)

    await viewModel.send(.task)
    await viewModel.send(.replyTapped(commentID: "comment-1"))
    await viewModel.send(.commentTextChanged("답글입니다"))
    await viewModel.send(.submitComment)

    #expect(viewModel.state.detail?.comments.first?.replies.map(\.content) == ["답글입니다"])
    #expect(viewModel.state.expandedReplyCommentIDs.contains("comment-1"))
    #expect(viewModel.state.commentText.isEmpty)
  }

  @Test("confirming comment deletion calls delete API and clears confirmation")
  func confirmingCommentDeletionCallsDeleteAPI() async {
    let service = TrackingFilterDetailService(detail: .sampleWithComment)
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", service: service, renderer: renderer)

    await viewModel.send(.task)
    await viewModel.send(.deleteCommentTapped(commentID: "comment-1"))
    await viewModel.send(.deleteCommentConfirmed)

    #expect(await service.deletedCommentIDs == ["comment-1"])
    #expect(viewModel.state.pendingDeleteCommentTarget == nil)
    #expect(viewModel.state.detail?.comments.isEmpty == true)
  }

  @Test("load marks detail mine when current user matches creator")
  func loadMarksDetailMineWhenCurrentUserMatchesCreator() async {
    let service = MockFilterDetailService(
      result: .success(.sample),
      currentUserIDResult: .success("user-1")
    )
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", service: service, renderer: renderer)

    await viewModel.send(.task)

    #expect(viewModel.state.currentUserID == "user-1")
    #expect(viewModel.state.isMine == true)
  }

  @Test("load marks detail not mine when current user differs from creator")
  func loadMarksDetailNotMineWhenCurrentUserDiffersFromCreator() async {
    let service = MockFilterDetailService(
      result: .success(.sample),
      currentUserIDResult: .success("user-2")
    )
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", service: service, renderer: renderer)

    await viewModel.send(.task)

    #expect(viewModel.state.currentUserID == "user-2")
    #expect(viewModel.state.isMine == false)
  }

  @Test("tap edit routes to update draft for own filter")
  func tapEditRoutesToUpdateDraftForOwnFilter() async {
    let service = MockFilterDetailService(
      result: .success(.sample),
      currentUserIDResult: .success("user-1")
    )
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let imageDataLoader = MockAuthenticatedImageDataLoader(data: Data([0x01, 0x02]))
    let viewModel = FilterDetailViewModel(
      filterID: "filter-123",
      service: service,
      renderer: renderer,
      imageDataLoader: imageDataLoader
    )

    await viewModel.send(.task)
    await viewModel.send(.tapEdit)

    guard case let .update(draft)? = viewModel.state.route else {
      Issue.record("Expected update route")
      return
    }

    #expect(draft.filterID == "filter-123")
    #expect(draft.name == "청록새록")
    #expect(draft.category == .landscape)
    #expect(draft.introduction == "맑은 청록빛")
    #expect(draft.representativeImageData == Data([0x01, 0x02]))

    await viewModel.send(.routeHandled)
    #expect(viewModel.state.route == nil)
  }

  @Test("tap edit does not route for another user's filter")
  func tapEditDoesNotRouteForOtherUserFilter() async {
    let service = MockFilterDetailService(
      result: .success(.sample),
      currentUserIDResult: .success("user-2")
    )
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(filterID: "filter-123", service: service, renderer: renderer)

    await viewModel.send(.task)
    await viewModel.send(.tapEdit)

    #expect(viewModel.state.route == nil)
  }

  @Test("like tap applies optimistic update and debounces final status")
  func likeTapOptimisticallyUpdatesAndDebounces() async throws {
    let service = TrackingFilterDetailService(detail: .sample)
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(
      filterID: "filter-123",
      service: service,
      renderer: renderer,
      likeDebounceDuration: .milliseconds(20)
    )

    await viewModel.send(.task)
    await viewModel.send(.likeTapped)

    #expect(viewModel.state.detail?.isLiked == true)
    #expect(viewModel.state.detail?.likeCount == 1)
    #expect(await service.likeStatuses.isEmpty)

    await viewModel.send(.likeTapped)

    #expect(viewModel.state.detail?.isLiked == false)
    #expect(viewModel.state.detail?.likeCount == 0)

    try await Task.sleep(for: .milliseconds(80))
    #expect(await service.likeStatuses == [false])
  }

  @Test("like debounce failure rolls back to pre-burst state")
  func likeDebounceFailureRollsBack() async throws {
    let service = TrackingFilterDetailService(
      detail: .sample,
      likeResults: [.failure(FilterDetailServiceError.serverError)]
    )
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(
      filterID: "filter-123",
      service: service,
      renderer: renderer,
      likeDebounceDuration: .milliseconds(20)
    )

    await viewModel.send(.task)
    await viewModel.send(.likeTapped)

    #expect(viewModel.state.detail?.isLiked == true)
    #expect(viewModel.state.detail?.likeCount == 1)

    try await Task.sleep(for: .milliseconds(80))
    #expect(viewModel.state.detail?.isLiked == false)
    #expect(viewModel.state.detail?.likeCount == 0)
  }

  private func paymentReadyViewModel(
    paymentResult: Result<Void, Error> = .success(())
  ) async -> FilterDetailViewModel {
    let service = MockFilterDetailService(result: .success(.undownloadedSample))
    let purchaseUseCase = MockFilterPurchaseUseCase(validateResult: paymentResult)
    let renderer = MockImageFilterRenderer(result: .success(.sample))
    let viewModel = FilterDetailViewModel(
      filterID: "filter-123",
      service: service,
      purchaseUseCase: purchaseUseCase,
      renderer: renderer
    )
    await viewModel.send(.task)
    await viewModel.send(.tapDownload)
    return viewModel
  }
}

private struct MockFilterDetailService: FilterDetailServicing {
  let result: Result<FilterDetail, Error>
  var currentUserIDResult: Result<String, Error> = .success("user-2")
  var createdComment = CommentReply(
    id: "reply-1",
    content: "답글입니다",
    createdAt: "2026-02-08T15:55:45.508Z",
    creator: .commentUser
  )

  func loadFilterDetail(filterID: String) async throws -> FilterDetail {
    try result.get()
  }

  func loadCurrentUserID() async throws -> String {
    try currentUserIDResult.get()
  }

  func deleteFilter(filterID: String) async throws {}

  func toggleLike(filterID: String, status: Bool) async throws -> Bool {
    status
  }

  func createComment(filterID: String, parentCommentID: String?, content: String) async throws -> CommentReply {
    CommentReply(
      id: createdComment.id,
      content: content,
      createdAt: createdComment.createdAt,
      creator: createdComment.creator
    )
  }

  func updateComment(filterID: String, commentID: String, content: String) async throws -> CommentReply {
    CommentReply(
      id: commentID,
      content: content,
      createdAt: createdComment.createdAt,
      creator: createdComment.creator
    )
  }

  func deleteComment(filterID: String, commentID: String) async throws {}
}

private struct MockAuthenticatedImageDataLoader: AuthenticatedImageDataLoading {
  let data: Data

  func loadImageData(from url: URL) async throws -> Data {
    data
  }
}

private actor TrackingFilterDetailService: FilterDetailServicing {
  let detail: FilterDetail
  private(set) var deletedCommentIDs: [String] = []
  private(set) var likeStatuses: [Bool] = []
  private var likeResults: [Result<Bool, Error>]

  init(detail: FilterDetail, likeResults: [Result<Bool, Error>] = []) {
    self.detail = detail
    self.likeResults = likeResults
  }

  func loadFilterDetail(filterID: String) async throws -> FilterDetail {
    detail
  }

  func loadCurrentUserID() async throws -> String {
    "user-1"
  }

  func deleteFilter(filterID: String) async throws {}

  func toggleLike(filterID: String, status: Bool) async throws -> Bool {
    likeStatuses.append(status)
    guard likeResults.isEmpty == false else {
      return status
    }
    return try likeResults.removeFirst().get()
  }

  func createComment(filterID: String, parentCommentID: String?, content: String) async throws -> CommentReply {
    CommentReply(id: "reply-1", content: content, createdAt: "2026-02-08T15:55:45.508Z", creator: .commentUser)
  }

  func updateComment(filterID: String, commentID: String, content: String) async throws -> CommentReply {
    CommentReply(id: commentID, content: content, createdAt: "2026-02-08T15:55:45.508Z", creator: .commentUser)
  }

  func deleteComment(filterID: String, commentID: String) async throws {
    deletedCommentIDs.append(commentID)
  }
}

private struct MockImageFilterRenderer: ImageFilterRendering {
  let result: Result<RenderedFilterImages, Error>

  func render(originalImageURL: URL, filterValues: FilterValues) async throws -> RenderedFilterImages {
    try result.get()
  }

  func render(originalImageData: Data, filterValues: FilterValues) async throws -> RenderedFilterImages {
    try result.get()
  }

  func renderPreview(
    originalImageData: Data,
    maxPixelSize: Int,
    filterValues: FilterValues
  ) async throws -> CGImage {
    try result.get().filtered
  }

  func renderComparisonPreview(
    originalImageData: Data,
    maxPixelSize: Int,
    filterValues: FilterValues
  ) async throws -> RenderedFilterImages {
    try result.get()
  }
}

private actor MockFilterPurchaseUseCase: FilterPurchaseUseCase {
  let validateResult: Result<Void, Error>
  private(set) var requestedDetailIDs: [String] = []
  private(set) var validatedResponses: [PortonePaymentResponse] = []

  init(validateResult: Result<Void, Error> = .success(())) {
    self.validateResult = validateResult
  }

  func makePaymentRequest(for detail: FilterDetail) async throws -> PortonePaymentRequest {
    requestedDetailIDs.append(detail.id)
    return PortonePaymentRequest(detail: detail, merchantUID: "D123456")
  }

  func validatePaymentResponse(_ response: PortonePaymentResponse) async throws {
    guard response.success else {
      throw FilterPurchaseError.paymentFailed(response.errorMessage)
    }

    guard let impUID = response.impUID, impUID.isEmpty == false else {
      throw FilterPurchaseError.missingApproval
    }

    validatedResponses.append(response)
    try validateResult.get()
  }
}

private actor SequencedFilterDetailService: FilterDetailServicing {
  private var results: [Result<FilterDetail, Error>]

  init(results: [Result<FilterDetail, Error>]) {
    self.results = results
  }

  func loadFilterDetail(filterID: String) async throws -> FilterDetail {
    guard results.isEmpty == false else {
      throw FilterDetailServiceError.invalidResponse
    }

    return try results.removeFirst().get()
  }

  func loadCurrentUserID() async throws -> String {
    "user-2"
  }

  func deleteFilter(filterID: String) async throws {}

  func toggleLike(filterID: String, status: Bool) async throws -> Bool {
    status
  }

  func createComment(filterID: String, parentCommentID: String?, content: String) async throws -> CommentReply {
    CommentReply(
      id: "reply-1",
      content: content,
      createdAt: "2026-02-08T15:55:45.508Z",
      creator: .commentUser
    )
  }

  func updateComment(filterID: String, commentID: String, content: String) async throws -> CommentReply {
    CommentReply(
      id: commentID,
      content: content,
      createdAt: "2026-02-08T15:55:45.508Z",
      creator: .commentUser
    )
  }

  func deleteComment(filterID: String, commentID: String) async throws {}
}

private extension CommentUser {
  static let commentUser = CommentUser(
    id: "user-2",
    nick: "andev",
    name: nil,
    profileImageURL: nil,
    introduction: nil,
    hashTags: []
  )
}

private extension FilterDetail {
  static let sample = FilterDetail(
    id: "filter-123",
    title: "청록새록",
    category: "풍경",
    introduction: "맑은 청록빛",
    description: "설명",
    originalImageURL: URL(string: "https://example.com/original.jpg"),
    fallbackFilteredImageURL: URL(string: "https://example.com/filtered.jpg"),
    creator: FilterDetailCreator(
      id: "user-1",
      nick: "SESAC YOON",
      name: "윤새싹",
      profileImageURL: nil,
      introduction: nil,
      hashTags: []
    ),
    metadata: FilterDetailMetadata(
      camera: "iPhone",
      lens: nil,
      focalLength: nil,
      aperture: nil,
      shutterSpeed: nil,
      iso: nil
    ),
    filterValues: .neutral,
    comments: [],
    isDownloaded: true,
    isLiked: false,
    likeCount: 0,
    buyerCount: 0,
    price: 0,
    hashTags: [],
    createdAt: nil,
    updatedAt: nil
  )

  static let undownloadedSample = FilterDetail(
    id: "filter-123",
    title: "청록새록",
    category: "풍경",
    introduction: "맑은 청록빛",
    description: "설명",
    originalImageURL: URL(string: "https://example.com/original.jpg"),
    fallbackFilteredImageURL: URL(string: "https://example.com/filtered.jpg"),
    creator: FilterDetailCreator(
      id: "user-1",
      nick: "SESAC YOON",
      name: "윤새싹",
      profileImageURL: nil,
      introduction: nil,
      hashTags: []
    ),
    metadata: FilterDetailMetadata(
      camera: "iPhone",
      lens: nil,
      focalLength: nil,
      aperture: nil,
      shutterSpeed: nil,
      iso: nil
    ),
    filterValues: .neutral,
    comments: [],
    isDownloaded: false,
    isLiked: false,
    likeCount: 0,
    buyerCount: 0,
    price: 2000,
    hashTags: [],
    createdAt: nil,
    updatedAt: nil
  )

  static let sampleWithComment = FilterDetail(
    id: "filter-123",
    title: "청록새록",
    category: "풍경",
    introduction: "맑은 청록빛",
    description: "설명",
    originalImageURL: URL(string: "https://example.com/original.jpg"),
    fallbackFilteredImageURL: URL(string: "https://example.com/filtered.jpg"),
    creator: FilterDetailCreator(
      id: "user-1",
      nick: "SESAC YOON",
      name: "윤새싹",
      profileImageURL: nil,
      introduction: nil,
      hashTags: []
    ),
    metadata: FilterDetailMetadata(
      camera: "iPhone",
      lens: nil,
      focalLength: nil,
      aperture: nil,
      shutterSpeed: nil,
      iso: nil
    ),
    filterValues: .neutral,
    comments: [
      Comment(
        id: "comment-1",
        content: "댓글입니다",
        createdAt: "2026-02-08T14:55:45.508Z",
        creator: .commentUser,
        replies: []
      ),
    ],
    isDownloaded: true,
    isLiked: false,
    likeCount: 0,
    buyerCount: 0,
    price: 0,
    hashTags: [],
    createdAt: nil,
    updatedAt: nil
  )
}

private extension CreatedOrder {
  static let sample = CreatedOrder(
    orderID: "order-123",
    orderCode: "D123456",
    totalPrice: 2000,
    createdAt: "2025-08-01T15:30:00.000Z",
    updatedAt: "2025-08-01T15:30:00.000Z"
  )
}

private extension PortonePaymentResponse {
  static func success(impUID: String?) -> PortonePaymentResponse {
    PortonePaymentResponse(
      success: true,
      impUID: impUID,
      merchantUID: "D123456",
      errorMessage: nil,
      errorCode: nil
    )
  }

  static let failure = PortonePaymentResponse(
    success: false,
    impUID: nil,
    merchantUID: "D123456",
    errorMessage: "카드 승인 실패",
    errorCode: "FAILED"
  )
}

private extension RenderedFilterImages {
  static let sample = RenderedFilterImages(
    original: TestImageFactory.makeCGImage(),
    filtered: TestImageFactory.makeCGImage()
  )
}

enum TestImageFactory {
  static func makeCGImage() -> CGImage {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
    let context = CGContext(
      data: nil,
      width: 2,
      height: 2,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    )!
    context.setFillColor(CGColor(red: 0.2, green: 0.8, blue: 0.6, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
    return context.makeImage()!
  }
}
