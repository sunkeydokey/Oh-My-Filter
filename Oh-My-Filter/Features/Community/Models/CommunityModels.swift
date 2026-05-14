import Foundation

nonisolated enum CommunityAttachment: Equatable, Sendable {
  case image(URL)
  case video(URL)
}

nonisolated enum CommunityTab: String, CaseIterable, Sendable {
  case all
  case posts
  case videos
  case liked

  var title: String {
    switch self {
    case .all:
      "전체"
    case .posts:
      "포스트"
    case .videos:
      "동영상"
    case .liked:
      "좋아요"
    }
  }
}

typealias CommunityCreator = CommentUser

nonisolated struct CommunityPost: Equatable, Identifiable, Sendable {
  let id: String
  let category: String
  let title: String
  let content: String
  let creator: CommunityCreator
  let attachments: [CommunityAttachment]
  let imagePaths: [String]
  let isLiked: Bool
  let likeCount: Int
  let comments: [CommunityComment]
  let createdAt: String
  let updatedAt: String

  var imageURLs: [URL] {
    attachments.compactMap { if case .image(let url) = $0 { url } else { nil } }
  }

  var videoURLs: [URL] {
    attachments.compactMap { if case .video(let url) = $0 { url } else { nil } }
  }

  var summary: String {
    content
  }

  var commentCount: Int {
    comments.count + comments.reduce(0) { $0 + $1.replies.count }
  }
}

typealias CommunityComment = Comment
typealias CommunityReply = CommentReply

nonisolated struct CommunityPostDraft: Equatable, Sendable {
  var category: String
  var title: String
  var content: String
  var existingFilePaths: [String]

  init(
    category: String = "",
    title: String = "",
    content: String = "",
    existingFilePaths: [String] = []
  ) {
    self.category = category
    self.title = title
    self.content = content
    self.existingFilePaths = existingFilePaths
  }
}

nonisolated enum CommunityPostMutationMode: Equatable, Sendable {
  case create
  case edit(postID: String)
}

nonisolated struct CommunityVideo: Equatable, Identifiable, Sendable, Hashable {
  let id: String
  let fileName: String
  let title: String
  let description: String
  let duration: Double
  let thumbnailURL: URL?
  let availableQualities: [String]
  let viewCount: Int
  let likeCount: Int
  let isLiked: Bool
  let createdAt: String
}

nonisolated enum CommunityFeedItem: Equatable, Identifiable, Sendable {
  case post(CommunityPost)
  case video(CommunityVideo)
  case videoRail([CommunityVideo])

  var id: String {
    switch self {
    case let .post(post):
      "post-\(post.id)"
    case let .video(video):
      "video-\(video.id)"
    case .videoRail:
      "video-rail"
    }
  }
}

nonisolated enum CommunityRoute: Hashable, Sendable {
  case postCreate
  case postDetail(postID: String)
  case postEdit(postID: String)
  case videoDetail(video: CommunityVideo)
}

nonisolated enum CommunityLoadPhase: Equatable, Sendable {
  case initial
  case loading
  case loaded
  case empty
  case error(message: String)
}

nonisolated enum CommunityEmptyStateKind: Equatable, Sendable {
  case noSearchResults
  case noLikedPosts
  case noContent

  var title: String {
    switch self {
    case .noSearchResults:
      "검색 결과가 없습니다"
    case .noLikedPosts:
      "좋아요한 항목이 없습니다"
    case .noContent:
      "아직 콘텐츠가 없습니다"
    }
  }
}

nonisolated struct CommunityPostPage: Equatable, Sendable {
  let posts: [CommunityPost]
  let nextCursor: String
}

nonisolated struct CommunityVideoPage: Equatable, Sendable {
  let videos: [CommunityVideo]
  let nextCursor: String
}
