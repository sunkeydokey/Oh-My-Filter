import Foundation

nonisolated enum VideoApiRouter: ApiRouter {
  case list
  case stream(videoId: String)
  case like(videoId: String)

  var url: String {
    switch self {
    case .list:
      EndPoint.Videos.list
    case let .stream(videoId):
      EndPoint.Videos.stream(videoId: videoId)
    case let .like(videoId):
      EndPoint.Videos.like(videoId: videoId)
    }
  }

  var method: HttpMethod {
    switch self {
    case .list, .stream:
      .get
    case .like:
      .post
    }
  }

  var contentType: ContentType {
    .json
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
