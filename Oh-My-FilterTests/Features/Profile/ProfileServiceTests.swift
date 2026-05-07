import Foundation
import Testing
@testable import Oh_My_Filter

struct ProfileServiceTests {
  @Test("profile router endpoints match docs")
  func profileRouterEndpoints() {
    #expect(UserApiRouter.getOwnProfile.url == "http://filter.sesac.kr:42598/v1/users/me/profile")
    #expect(UserApiRouter.getOwnProfile.method == .get)
    #expect(UserApiRouter.editUserProfile.method == .put)
    #expect(UserApiRouter.uploadProfileImage.method == .post)
    #expect(UserApiRouter.updateDeviceToken.method == .put)
  }

  @Test("my profile decodes response")
  func myProfileDecodes() async throws {
    let manager = MockProfileNetworkManager()
    let service = LiveProfileService(networkManager: manager)
    await manager.enqueueResponse(NetworkResponse(data: Self.profileData, statusCode: 200))

    let profile = try await service.loadMyProfile()

    #expect(profile.userID == "user-1")
    #expect(profile.email == "sunny@example.com")
    #expect(profile.displayName == "Sunny")
    #expect(profile.phoneNumber == "010-1234-5678")
    #expect(profile.hashTags == ["#맑음"])
  }

  @Test("profile image upload uses multipart profile field")
  func profileImageUploadUsesProfileField() async throws {
    let manager = MockProfileNetworkManager()
    let service = LiveProfileService(networkManager: manager)
    await manager.enqueueResponse(
      NetworkResponse(data: Data(#"{"profileImage":"/data/profiles/image.jpg"}"#.utf8), statusCode: 200)
    )

    let path = try await service.uploadProfileImage(
      multipartFiles: [
        MultipartFilePart(fieldName: "profile", fileName: "profile.jpg", mimeType: "image/jpeg", data: Data())
      ]
    )

    #expect(path == "/data/profiles/image.jpg")
    #expect(await manager.capturedMultipartFiles.map(\.fieldName) == ["profile"])
  }
}

struct OrderHistoryServiceTests {
  @Test("order list router uses documented endpoint")
  func orderListRouterUsesDocumentedEndpoint() {
    #expect(OrderApiRouter.list.url == "http://filter.sesac.kr:42598/v1/orders")
    #expect(OrderApiRouter.list.method == .get)
    #expect(OrderApiRouter.list.requiresAuthorizationHeader)
  }

  @Test("order history decodes list response")
  func orderHistoryDecodes() async throws {
    let manager = MockProfileNetworkManager()
    let service = LiveOrderHistoryService(networkManager: manager)
    await manager.enqueueResponse(NetworkResponse(data: Self.orderData, statusCode: 200))

    let orders = try await service.loadOrders()

    #expect(orders.count == 1)
    #expect(orders[0].orderCode == "A123456")
    #expect(orders[0].filter.title == "풍경 필터")
    #expect(orders[0].filter.creator.nick == "sesac")
  }
}

private actor MockProfileNetworkManager: AuthenticatedNetworkManaging {
  private var queuedResults: [Result<NetworkResponse, Error>] = []
  private(set) var capturedMultipartFiles: [MultipartFilePart] = []

  func enqueueResponse(_ response: NetworkResponse) {
    queuedResults.append(.success(response))
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

  func request<Router: ApiRouter>(
    _ router: Router,
    multipartFiles: [MultipartFilePart],
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    capturedMultipartFiles = multipartFiles
    return try nextResult()
  }

  private func nextResult() throws -> NetworkResponse {
    guard queuedResults.isEmpty == false else {
      throw NetworkError.invalidResponse
    }
    return try queuedResults.removeFirst().get()
  }
}

private extension ProfileServiceTests {
  static let profileData = Data(
    """
    {
      "user_id": "user-1",
      "email": "sunny@example.com",
      "nick": "sunny",
      "name": "Sunny",
      "introduction": "자연광 필터와 따뜻한 톤을 즐겨 쓰는 사용자",
      "profileImage": "/data/profiles/profile.jpg",
      "phoneNum": "010-1234-5678",
      "hashTags": ["#맑음"]
    }
    """.utf8
  )
}

private extension OrderHistoryServiceTests {
  static let orderData = Data(
    """
    {
      "data": [
        {
          "order_id": "order-1",
          "order_code": "A123456",
          "filter": {
            "id": "filter-1",
            "category": "풍경",
            "title": "풍경 필터",
            "description": "풍경 사진을 더 멋지게!",
            "files": ["/data/filters/preview.jpg"],
            "price": 170,
            "creator": {
              "user_id": "creator-1",
              "nick": "sesac",
              "name": "김새싹",
              "introduction": "프로필 소개입니다.",
              "profileImage": "/data/profiles/creator.jpg",
              "hashTags": ["#맑음"]
            },
            "filter_values": {},
            "createdAt": "2025-06-10T14:30:00.000Z",
            "updatedAt": "2025-06-10T14:30:00.000Z"
          },
          "paidAt": "2025-06-10T14:30:00.000Z",
          "createdAt": "2025-06-10T14:30:00.000Z",
          "updatedAt": "2025-06-10T14:30:00.000Z"
        }
      ]
    }
    """.utf8
  )
}
