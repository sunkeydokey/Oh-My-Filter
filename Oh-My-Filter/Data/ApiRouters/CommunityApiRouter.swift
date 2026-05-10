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
  case updateComment(postID: String, commentID: String)
  case deleteComment(postID: String, commentID: String)

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
    case let .updateComment(postID, commentID), let .deleteComment(postID, commentID):
      EndPoint.Posts.comment(postID: postID, commentID: commentID)
    }
  }

  var method: HttpMethod {
    switch self {
    case .posts, .searchPosts, .likedPosts, .postDetail:
      .get
    case .uploadFiles, .createPost, .like, .createComment:
      .post
    case .updatePost, .updateComment:
      .put
    case .deletePost, .deleteComment:
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
