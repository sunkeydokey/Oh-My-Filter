import Foundation
import Testing
@testable import Oh_My_Filter

struct PaymentServiceTests {
  @Test("validation router uses POST payments validation endpoint")
  func validationRouterUsesPostEndpoint() {
    #expect(PaymentApiRouter.validation.url == "http://filter.sesac.kr:42598/v1/payments/validation")
    #expect(PaymentApiRouter.validation.method == .post)
    #expect(PaymentApiRouter.validation.requiresAuthorizationHeader)
  }

  @Test("validation request encodes snake case body")
  func validationRequestEncodesSnakeCaseBody() throws {
    let data = try JSONEncoder().encode(
      PaymentValidationRequest(impUid: "imp-123")
    )
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])

    #expect(json == ["imp_uid": "imp-123"])
  }

  @Test("validation 2xx succeeds")
  func validation2xxSucceeds() async throws {
    let manager = MockPaymentNetworkManager()
    let service = LivePaymentService(networkManager: manager)
    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 204))

    try await service.validatePayment(
      request: PaymentValidationRequest(impUid: "imp-123")
    )
  }

  @Test("validation non 2xx maps to validation failed")
  func validationNon2xxMapsToValidationFailed() async {
    let manager = MockPaymentNetworkManager()
    let service = LivePaymentService(networkManager: manager)
    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: 409))

    await #expect(throws: PaymentServiceError.validationFailed) {
      try await service.validatePayment(
        request: PaymentValidationRequest(impUid: "imp-123")
      )
    }
  }

  @Test("validation transport error maps to payment transport")
  func validationTransportErrorMapsToPaymentTransport() async {
    let manager = MockPaymentNetworkManager()
    let service = LivePaymentService(networkManager: manager)
    await manager.enqueueFailure(NetworkError.transport)

    await #expect(throws: PaymentServiceError.transport) {
      try await service.validatePayment(
        request: PaymentValidationRequest(impUid: "imp-123")
      )
    }
  }
}

struct OrderServiceTests {
  @Test("order router uses POST documented endpoint")
  func orderRouterUsesPostEndpoint() {
    #expect(OrderApiRouter.create.url == "http://filter.sesac.kr:42598/v1/orders")
    #expect(OrderApiRouter.create.method == .post)
    #expect(OrderApiRouter.create.requiresAuthorizationHeader)
  }

  @Test("order request encodes snake case body")
  func orderRequestEncodesSnakeCaseBody() throws {
    let data = try JSONEncoder().encode(
      OrderCreateRequest(filterId: "filter-123", totalPrice: 170)
    )
    let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

    #expect(json["filter_id"] as? String == "filter-123")
    #expect(json["total_price"] as? Int == 170)
  }

  @Test("order service decodes response")
  func orderServiceDecodesResponse() async throws {
    let manager = MockPaymentNetworkManager()
    let service = LiveOrderService(networkManager: manager)
    await manager.enqueueResponse(NetworkResponse(data: Self.orderData, statusCode: 200))

    let order = try await service.createOrder(
      request: OrderCreateRequest(filterId: "filter-123", totalPrice: 170)
    )

    #expect(order.orderID == "671c9e2f8d7a6b5c4d3e2f1a")
    #expect(order.orderCode == "D123456")
    #expect(order.totalPrice == 170)
  }

  @Test("order documented status codes map to domain errors")
  func orderStatusCodesMapToDomainErrors() async {
    await expectOrderError(statusCode: 400, error: .invalidRequest)
    await expectOrderError(statusCode: 404, error: .filterNotFound)
    await expectOrderError(statusCode: 409, error: .alreadyPurchased)
  }

  private func expectOrderError(statusCode: Int, error: OrderServiceError) async {
    let manager = MockPaymentNetworkManager()
    let service = LiveOrderService(networkManager: manager)
    await manager.enqueueResponse(NetworkResponse(data: Data(), statusCode: statusCode))

    await #expect(throws: error) {
      try await service.createOrder(
        request: OrderCreateRequest(filterId: "filter-123", totalPrice: 170)
      )
    }
  }
}

struct FilterPurchaseUseCaseTests {
  @Test("make payment request creates order and maps detail to Portone request")
  func makePaymentRequestCreatesOrder() async throws {
    let orderService = MockOrderService(result: .success(.sample))
    let paymentService = MockPaymentService()
    let useCase = LiveFilterPurchaseUseCase(orderService: orderService, paymentService: paymentService)

    let request = try await useCase.makePaymentRequest(for: .undownloadedFilter)

    #expect(await orderService.requests == [OrderCreateRequest(filterId: "filter-123", totalPrice: 2000)])
    #expect(request.merchantUID == "D123456")
    #expect(request.amount == "2000")
    #expect(request.name == "청록새록")
  }

  @Test("make payment request rejects already purchased filter")
  func makePaymentRequestRejectsPurchasedFilter() async {
    let orderService = MockOrderService(result: .success(.sample))
    let paymentService = MockPaymentService()
    let useCase = LiveFilterPurchaseUseCase(orderService: orderService, paymentService: paymentService)

    await #expect(throws: FilterPurchaseError.alreadyPurchased) {
      try await useCase.makePaymentRequest(for: .downloadedFilter)
    }

    #expect(await orderService.requests.isEmpty)
  }

  @Test("successful payment response validates with server")
  func successfulPaymentResponseValidatesWithServer() async throws {
    let orderService = MockOrderService(result: .success(.sample))
    let paymentService = MockPaymentService()
    let useCase = LiveFilterPurchaseUseCase(orderService: orderService, paymentService: paymentService)

    try await useCase.validatePaymentResponse(.success(impUID: "imp-123"))

    #expect(await paymentService.requests == [PaymentValidationRequest(impUid: "imp-123")])
  }

  @Test("payment response without imp uid fails before validation")
  func paymentResponseWithoutImpUIDFailsBeforeValidation() async {
    let orderService = MockOrderService(result: .success(.sample))
    let paymentService = MockPaymentService()
    let useCase = LiveFilterPurchaseUseCase(orderService: orderService, paymentService: paymentService)

    await #expect(throws: FilterPurchaseError.missingApproval) {
      try await useCase.validatePaymentResponse(.success(impUID: nil))
    }

    #expect(await paymentService.requests.isEmpty)
  }

  @Test("failed payment response preserves user message")
  func failedPaymentResponsePreservesUserMessage() async {
    let orderService = MockOrderService(result: .success(.sample))
    let paymentService = MockPaymentService()
    let useCase = LiveFilterPurchaseUseCase(orderService: orderService, paymentService: paymentService)

    await #expect(throws: FilterPurchaseError.paymentFailed("카드 승인 실패")) {
      try await useCase.validatePaymentResponse(.failure)
    }

    #expect(await paymentService.requests.isEmpty)
  }

  @Test("order and payment service errors propagate")
  func serviceErrorsPropagate() async {
    let failingOrderService = MockOrderService(result: .failure(OrderServiceError.transport))
    let paymentService = MockPaymentService(result: .failure(PaymentServiceError.validationFailed))
    let useCase = LiveFilterPurchaseUseCase(orderService: failingOrderService, paymentService: paymentService)

    await #expect(throws: OrderServiceError.transport) {
      try await useCase.makePaymentRequest(for: .undownloadedFilter)
    }

    await #expect(throws: PaymentServiceError.validationFailed) {
      try await useCase.validatePaymentResponse(.success(impUID: "imp-123"))
    }
  }
}

private actor MockPaymentNetworkManager: AuthenticatedNetworkManaging {
  private var queuedResults: [Result<NetworkResponse, Error>] = []

  func enqueueResponse(_ response: NetworkResponse) {
    queuedResults.append(.success(response))
  }

  func enqueueFailure(_ error: Error) {
    queuedResults.append(.failure(error))
  }

  func request<Router: ApiRouter>(
    _ router: Router,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try nextResult()
  }

  func request<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    try nextResult()
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }

    return try queuedResults.removeFirst().get()
  }
}

private actor MockOrderService: OrderServicing {
  let result: Result<CreatedOrder, Error>
  private(set) var requests: [OrderCreateRequest] = []

  init(result: Result<CreatedOrder, Error>) {
    self.result = result
  }

  func createOrder(request: OrderCreateRequest) async throws -> CreatedOrder {
    requests.append(request)
    return try result.get()
  }
}

private actor MockPaymentService: PaymentServicing {
  let result: Result<Void, Error>
  private(set) var requests: [PaymentValidationRequest] = []

  init(result: Result<Void, Error> = .success(())) {
    self.result = result
  }

  func validatePayment(request: PaymentValidationRequest) async throws {
    requests.append(request)
    try result.get()
  }
}

private extension OrderServiceTests {
  static let orderData = Data(
    """
    {
      "data": {
        "order_id": "671c9e2f8d7a6b5c4d3e2f1a",
        "order_code": "D123456",
        "total_price": 170,
        "createdAt": "2025-08-01T15:30:00.000Z",
        "updatedAt": "2025-08-01T15:30:00.000Z"
      }
    }
    """.utf8
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

private extension FilterDetail {
  static let undownloadedFilter = filter(isDownloaded: false)
  static let downloadedFilter = filter(isDownloaded: true)

  static func filter(isDownloaded: Bool) -> FilterDetail {
    FilterDetail(
      id: "filter-123",
      title: "청록새록",
      category: "풍경",
      introduction: "맑은 청록빛",
      description: "설명",
      originalImageURL: nil,
      fallbackFilteredImageURL: nil,
      creator: FilterDetailCreator(
        id: "user-1",
        nick: "SESAC YOON",
        name: "윤새싹",
        profileImageURL: nil,
        introduction: nil,
        hashTags: []
      ),
      metadata: FilterDetailMetadata(
        camera: nil,
        lens: nil,
        focalLength: nil,
        aperture: nil,
        shutterSpeed: nil,
        iso: nil
      ),
      filterValues: .neutral,
      comments: [],
      isDownloaded: isDownloaded,
      isLiked: false,
      likeCount: 0,
      buyerCount: 0,
      price: 2000,
      hashTags: [],
      createdAt: nil,
      updatedAt: nil
    )
  }
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
