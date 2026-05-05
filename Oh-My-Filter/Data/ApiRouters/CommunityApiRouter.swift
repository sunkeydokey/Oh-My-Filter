import Foundation

nonisolated enum CommunityApiRouter: ApiRouter {
  case uploadFiles
  case createPost
  case posts
  case searchPosts
  case likedPosts
  case postDetail(postID: String)
  case updatePost(postID: String)
  case deletePost(postID: String)
  case like(postID: String)
  case createComment(postID: String)

  var url: String {
    switch self {
    case .uploadFiles:
      EndPoint.Posts.files
    case .createPost:
      EndPoint.Posts.create
    case .posts:
      EndPoint.Posts.geolocation
    case .searchPosts:
      EndPoint.Posts.search
    case .likedPosts:
      EndPoint.Posts.likedMe
    case let .postDetail(postID):
      EndPoint.Posts.detail(postID: postID)
    case let .updatePost(postID), let .deletePost(postID):
      EndPoint.Posts.detail(postID: postID)
    case let .like(postID):
      EndPoint.Posts.like(postID: postID)
    case let .createComment(postID):
      EndPoint.Posts.comments(postID: postID)
    }
  }

  var method: HttpMethod {
    switch self {
    case .posts, .searchPosts, .likedPosts, .postDetail:
      .get
    case .uploadFiles, .createPost, .like, .createComment:
      .post
    case .updatePost:
      .put
    case .deletePost:
      .delete
    }
  }

  var contentType: ContentType {
    switch self {
    case .uploadFiles:
      .multipart
    default:
      .json
    }
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
