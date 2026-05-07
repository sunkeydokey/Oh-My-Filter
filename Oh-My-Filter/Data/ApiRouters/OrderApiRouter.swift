import Foundation

nonisolated enum OrderApiRouter: ApiRouter {
  case create
  case list

  var url: String {
    switch self {
    case .create, .list:
      EndPoint.Orders.create
    }
  }

  var method: HttpMethod {
    switch self {
    case .create:
      .post
    case .list:
      .get
    }
  }

  var contentType: ContentType {
    .json
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
