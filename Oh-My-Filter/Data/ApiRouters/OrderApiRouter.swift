import Foundation

nonisolated enum OrderApiRouter: ApiRouter {
  case create

  var url: String {
    switch self {
    case .create:
      EndPoint.Orders.create
    }
  }

  var method: HttpMethod {
    .post
  }

  var contentType: ContentType {
    .json
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
