import Foundation

nonisolated enum AuthApiRouter: ApiRouter {
  case refresh

  var url: String {
    switch self {
    case .refresh:
      EndPoint.Auth.refresh
    }
  }

  var method: HttpMethod {
    switch self {
    case .refresh:
      .get
    }
  }

  var contentType: ContentType {
    .json
  }
}
