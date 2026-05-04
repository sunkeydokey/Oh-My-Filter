import Foundation

nonisolated enum FilterApiRouter: ApiRouter {
  case list
  case create
  case uploadFiles
  case detail(filterID: String)
  case update(filterID: String)

  var url: String {
    switch self {
    case .list, .create:
      EndPoint.Filters.list
    case .uploadFiles:
      EndPoint.Filters.files
    case let .detail(filterID):
      EndPoint.Filters.detail(filterID: filterID)
    case let .update(filterID):
      EndPoint.Filters.detail(filterID: filterID)
    }
  }

  var method: HttpMethod {
    switch self {
    case .list, .detail:
      .get
    case .create, .uploadFiles:
      .post
    case .update:
      .put
    }
  }

  var contentType: ContentType {
    switch self {
    case .uploadFiles:
      .multipart
    case .list, .create, .detail, .update:
      .json
    }
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
