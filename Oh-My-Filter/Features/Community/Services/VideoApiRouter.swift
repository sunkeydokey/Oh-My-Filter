import Foundation

nonisolated enum VideoApiRouter: ApiRouter {
  case list

  var url: String {
    switch self {
    case .list:
      EndPoint.Videos.list
    }
  }

  var method: HttpMethod {
    .get
  }

  var contentType: ContentType {
    .json
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
