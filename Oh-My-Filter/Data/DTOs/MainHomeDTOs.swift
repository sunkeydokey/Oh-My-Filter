import Foundation

nonisolated struct MainTodayFilterDTO: Codable, Sendable {
  let filterId: String
  let category: String?
  let title: String
  let introduction: String?
  let description: String
  let files: [String]
  let creator: MainCreatorDTO?
  let isLiked: Bool
  let likeCount: Int
  let buyerCount: Int
  let createdAt: String
  let updatedAt: String

  init(
    filterId: String,
    category: String?,
    title: String,
    introduction: String?,
    description: String,
    files: [String],
    creator: MainCreatorDTO?,
    isLiked: Bool = false,
    likeCount: Int = 0,
    buyerCount: Int = 0,
    createdAt: String,
    updatedAt: String
  ) {
    self.filterId = filterId
    self.category = category
    self.title = title
    self.introduction = introduction
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
      introduction: try container.decodeIfPresent(String.self, forKey: .introduction),
      description: try container.decode(String.self, forKey: .description),
      files: try container.decode([String].self, forKey: .files),
      creator: try container.decodeIfPresent(MainCreatorDTO.self, forKey: .creator),
      isLiked: try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false,
      likeCount: try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0,
      buyerCount: try container.decodeIfPresent(Int.self, forKey: .buyerCount) ?? 0,
      createdAt: try container.decode(String.self, forKey: .createdAt),
      updatedAt: try container.decode(String.self, forKey: .updatedAt)
    )
  }
}

nonisolated struct MainHotTrendFiltersResponseDTO: Codable, Sendable {
  let data: [MainHotTrendFilterDTO]
}

nonisolated struct MainBannersResponseDTO: Codable, Sendable {
  let data: [MainBannerDTO]
}

nonisolated struct MainBannerDTO: Codable, Sendable {
  let name: String
  let imageUrl: String
  let payload: MainBannerPayloadDTO
}

nonisolated struct MainBannerPayloadDTO: Codable, Sendable {
  let type: MainBannerPayloadTypeDTO
  let value: String
}

nonisolated enum MainBannerPayloadTypeDTO: String, Codable, Sendable {
  case webview = "WEBVIEW"
}

nonisolated struct MainHotTrendFilterDTO: Codable, Sendable {
  let filterId: String
  let category: String?
  let title: String
  let description: String
  let files: [String]
  let creator: MainCreatorDTO?
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
    creator: MainCreatorDTO?,
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
      files: try container.decode([String].self, forKey: .files),
      creator: try container.decodeIfPresent(MainCreatorDTO.self, forKey: .creator),
      isLiked: try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false,
      likeCount: try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0,
      buyerCount: try container.decodeIfPresent(Int.self, forKey: .buyerCount) ?? 0,
      createdAt: try container.decode(String.self, forKey: .createdAt),
      updatedAt: try container.decode(String.self, forKey: .updatedAt)
    )
  }
}

nonisolated struct MainTodayAuthorResponseDTO: Codable, Sendable {
  let author: MainTodayAuthorDTO
  let filters: [MainTodayAuthorFilterDTO]
}

nonisolated struct MainTodayAuthorDTO: Codable, Sendable {
  let userId: String
  let nick: String
  let profileImage: String?
  let introduction: String?
  let name: String?
  let hashTags: [String]?
  let description: String?
}

nonisolated struct MainTodayAuthorFilterDTO: Codable, Sendable {
  let filterId: String
  let category: String?
  let title: String
  let description: String
  let files: [String]
  let creator: MainCreatorDTO?
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
    creator: MainCreatorDTO?,
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
      files: try container.decode([String].self, forKey: .files),
      creator: try container.decodeIfPresent(MainCreatorDTO.self, forKey: .creator),
      isLiked: try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false,
      likeCount: try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0,
      buyerCount: try container.decodeIfPresent(Int.self, forKey: .buyerCount) ?? 0,
      createdAt: try container.decode(String.self, forKey: .createdAt),
      updatedAt: try container.decode(String.self, forKey: .updatedAt)
    )
  }
}

nonisolated struct MainCreatorDTO: Codable, Sendable {
  let userId: String
  let nick: String
  let profileImage: String?
  let name: String?
  let introduction: String?
  let hashTags: [String]?
  let createdAt: String?
  let updatedAt: String?
}
