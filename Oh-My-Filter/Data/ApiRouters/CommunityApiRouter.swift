import Foundation

nonisolated enum CommunityApiRouter: ApiRouter {
  case posts
  case searchPosts
  case likedPosts
  case postDetail(postID: String)

  var url: String {
    switch self {
    case .posts:
      EndPoint.Posts.geolocation
    case .searchPosts:
      EndPoint.Posts.search
    case .likedPosts:
      EndPoint.Posts.likedMe
    case let .postDetail(postID):
      EndPoint.Posts.detail(postID: postID)
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
