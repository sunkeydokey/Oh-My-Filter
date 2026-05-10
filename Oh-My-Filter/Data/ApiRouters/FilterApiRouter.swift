import Foundation

nonisolated enum FilterApiRouter: ApiRouter {
  case list
  case create
  case uploadFiles
  case detail(filterID: String)
  case update(filterID: String)
  case delete(filterID: String)
  case createComment(filterID: String)
  case updateComment(filterID: String, commentID: String)
  case deleteComment(filterID: String, commentID: String)

  var url: String {
    switch self {
    case .list, .create:
      EndPoint.Filters.list
    case .uploadFiles:
      EndPoint.Filters.files
    case let .detail(filterID):
      EndPoint.Filters.detail(filterID: filterID)
    case let .update(filterID), let .delete(filterID):
      EndPoint.Filters.detail(filterID: filterID)
    case let .createComment(filterID):
      EndPoint.Filters.comments(filterID: filterID)
    case let .updateComment(filterID, commentID), let .deleteComment(filterID, commentID):
      EndPoint.Filters.comment(filterID: filterID, commentID: commentID)
    }
  }

  var method: HttpMethod {
    switch self {
    case .list, .detail:
      .get
    case .create, .uploadFiles, .createComment:
      .post
    case .update, .updateComment:
      .put
    case .delete, .deleteComment:
      .delete
    }
  }

  var contentType: ContentType {
    switch self {
    case .uploadFiles:
      .multipart
    case .list, .create, .detail, .update, .delete, .createComment, .updateComment, .deleteComment:
      .json
    }
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
