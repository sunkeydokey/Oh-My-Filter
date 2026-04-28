import Foundation

nonisolated enum FilterApiRouter: ApiRouter {
  case detail(filterID: String)

  var url: String {
    switch self {
    case let .detail(filterID):
      EndPoint.Filters.detail(filterID: filterID)
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
