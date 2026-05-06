import Foundation

nonisolated struct CommunityPostPageDTO: Decodable, Sendable {
  let data: [CommunityPostDTO]
  let nextCursor: String
}

nonisolated struct CommunityPostListDTO: Decodable, Sendable {
  let data: [CommunityPostDTO]
}

nonisolated struct CommunityPostDTO: Decodable, Sendable {
  let postId: String
  let category: String
  let title: String
  let content: String
  let creator: CommentUserDTO
  let files: [String]
  let isLike: Bool
  let likeCount: Int
  let comments: [CommentDTO]?
  let createdAt: String
  let updatedAt: String

  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.postId = try container.decode(String.self, forKey: .postId)
    self.category = try container.decode(String.self, forKey: .category)
    self.title = try container.decode(String.self, forKey: .title)
    self.content = try container.decode(String.self, forKey: .content)
    self.creator = try container.decode(CommentUserDTO.self, forKey: .creator)
    self.files = try container.decodeIfPresent([String].self, forKey: .files) ?? []
    self.isLike = try container.decodeIfPresent(Bool.self, forKey: .isLike) ?? false
    self.likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
    self.comments = try container.decodeIfPresent([CommentDTO].self, forKey: .comments)
    self.createdAt = try container.decode(String.self, forKey: .createdAt)
    self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
  }

  private enum CodingKeys: String, CodingKey {
    case postId
    case category
    case title
    case content
    case creator
    case files
    case isLike
    case likeCount
    case comments
    case createdAt
    case updatedAt
  }
}

nonisolated struct CommunityPostRequestDTO: Encodable, Sendable {
  let category: String
  let title: String
  let content: String
  let latitude: Double
  let longitude: Double
  let files: [String]
}

nonisolated struct CommunityPostLikeRequestDTO: Encodable, Sendable {
  let like_status: Bool
}

nonisolated struct CommunityPostLikeResponseDTO: Decodable, Sendable {
  let likeStatus: Bool
}

nonisolated struct CommunityVideoPageDTO: Codable, Sendable {
  let data: [CommunityVideoDTO]
  let nextCursor: String?
}

nonisolated struct CommunityVideoDTO: Codable, Sendable {
  let videoId: String
  let fileName: String
  let title: String
  let description: String
  let duration: Double
  let thumbnailUrl: String
  let availableQualities: [String]
  let viewCount: Int
  let likeCount: Int
  let isLiked: Bool
  let createdAt: String
}

extension CommunityPostPageDTO {
  nonisolated func toDomain() -> CommunityPostPage {
    CommunityPostPage(
      posts: data.map { $0.toDomain() },
      nextCursor: nextCursor
    )
  }
}

extension CommunityPostListDTO {
  nonisolated func toDomain() -> [CommunityPost] {
    data.map { $0.toDomain() }
  }
}

extension CommunityPostDTO {
  nonisolated func toDomain() -> CommunityPost {
    CommunityPost(
      id: postId,
      category: category,
      title: title,
      content: content,
      creator: creator.toDomain(),
      attachments: files.compactMap { attachment(from: $0) },
      imagePaths: files,
      isLiked: isLike,
      likeCount: likeCount,
      comments: comments?.map { $0.toDomain() } ?? [],
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }

  private nonisolated func attachment(from path: String) -> CommunityAttachment? {
    guard let url = AuthenticatedRemoteImageSupport.url(from: path) else { return nil }
    let ext = (path as NSString).pathExtension.lowercased()
    let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv"]
    return videoExtensions.contains(ext) ? .video(url) : .image(url)
  }
}

extension CommunityVideoPageDTO {
  nonisolated func toDomain() -> CommunityVideoPage {
    CommunityVideoPage(
      videos: data.map { $0.toDomain() },
      nextCursor: nextCursor ?? "0"
    )
  }
}

extension CommunityVideoDTO {
  nonisolated func toDomain() -> CommunityVideo {
    CommunityVideo(
      id: videoId,
      fileName: fileName,
      title: title,
      description: description,
      duration: duration,
      thumbnailURL: AuthenticatedRemoteImageSupport.url(from: thumbnailUrl),
      availableQualities: availableQualities,
      viewCount: viewCount,
      likeCount: likeCount,
      isLiked: isLiked,
      createdAt: createdAt
    )
  }
}
