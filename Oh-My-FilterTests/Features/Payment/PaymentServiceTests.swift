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
