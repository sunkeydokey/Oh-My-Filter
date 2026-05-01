import Foundation

nonisolated struct FeedFilterPageDTO: Codable, Sendable {
  let data: [FeedFilterDTO]
  let nextCursor: String
}

nonisolated struct FeedFilterDTO: Codable, Sendable {
  let filterId: String
  let category: String?
  let title: String
  let description: String
  let files: [String]
  let creator: FeedCreatorDTO?
  let isLiked: Bool
  let likeCount: Int
  let buyerCount: Int
  let createdAt: String
  let updatedAt: String

  init(
    filterId: String,
    category: String?,
    title: String,
    description: String,
    files: [String],
    creator: FeedCreatorDTO?,
    isLiked: Bool = false,
    likeCount: Int = 0,
    buyerCount: Int = 0,
    createdAt: String,
    updatedAt: String
  ) {
    self.filterId = filterId
    self.category = category
    self.title = title
    self.description = description
    self.files = files
    self.creator = creator
    self.isLiked = isLiked
    self.likeCount = likeCount
    self.buyerCount = buyerCount
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.init(
      filterId: try container.decode(String.self, forKey: .filterId),
      category: try container.decodeIfPresent(String.self, forKey: .category),
      title: try container.decode(String.self, forKey: .title),
      description: try container.decode(String.self, forKey: .description),
      files: try container.decodeIfPresent([String].self, forKey: .files) ?? [],
      creator: try container.decodeIfPresent(FeedCreatorDTO.self, forKey: .creator),
      isLiked: try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false,
      likeCount: try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0,
      buyerCount: try container.decodeIfPresent(Int.self, forKey: .buyerCount) ?? 0,
      createdAt: try container.decode(String.self, forKey: .createdAt),
      updatedAt: try container.decode(String.self, forKey: .updatedAt)
    )
  }
}

nonisolated struct FeedCreatorDTO: Codable, Sendable {
  let userId: String
  let nick: String
  let profileImage: String?
  let name: String?
  let introduction: String?
  let hashTags: [String]?
}

extension FeedFilterPageDTO {
  nonisolated func toDomain() -> FeedPage {
    FeedPage(
      filters: data.map { $0.toDomain() },
      nextCursor: nextCursor
    )
  }
}

extension FeedFilterDTO {
  nonisolated func toDomain() -> FeedFilter {
    FeedFilter(
      id: filterId,
      title: title,
      description: description,
      category: category,
      imageURL: AuthenticatedRemoteImageSupport.url(from: files.first),
      creatorNick: creator?.nick,
      likeCount: likeCount,
      buyerCount: buyerCount,
      createdAt: createdAt
    )
  }
}
