import Foundation

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

nonisolated struct CommunityCreator: Equatable, Sendable {
  let id: String
  let nick: String
  let name: String?
  let profileImageURL: URL?
  let introduction: String?
  let hashTags: [String]
}

nonisolated struct CommunityPost: Equatable, Identifiable, Sendable {
  let id: String
  let category: String
  let title: String
  let content: String
  let creator: CommunityCreator
  let imageURLs: [URL]
  let imagePaths: [String]
  let isLiked: Bool
  let likeCount: Int
  let comments: [CommunityComment]
  let createdAt: String
  let updatedAt: String

  var summary: String {
    content
  }

  var commentCount: Int {
    comments.count + comments.reduce(0) { $0 + $1.replies.count }
  }
}

nonisolated struct CommunityComment: Equatable, Identifiable, Sendable {
  let id: String
  let content: String
  let createdAt: String
  let creator: CommunityCreator
  let replies: [CommunityReply]
}

nonisolated struct CommunityReply: Equatable, Identifiable, Sendable {
  let id: String
  let content: String
  let createdAt: String
  let creator: CommunityCreator
}

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
    case let .videoRail(videos):
      "video-rail-\(videos.map(\.id).joined(separator: "-"))"
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
