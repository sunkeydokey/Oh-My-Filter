import Foundation

nonisolated struct FilterResponseDTO: Decodable, Sendable {
  let filterId: String
  let category: String?
  let title: String
  let introduction: String?
  let description: String?
  let files: [String]
  let creator: FilterDetailUserDTO?
  let metadata: FilterMetadataDTO?
  let filterValues: FilterValuesDTO?
  let comments: [FilterCommentDTO]
  let isDownloaded: Bool
  let isLiked: Bool
  let likeCount: Int
  let buyerCount: Int
  let price: Int
  let hashTags: [String]
  let createdAt: String?
  let updatedAt: String?

  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let wrappedData = try container.decodeIfPresent(FilterResponseDTO.self, forKey: .data)
    if let wrappedData {
      self = wrappedData
      return
    }

    filterId = try container.decodeFlexibleString(forKey: .filterId) ?? ""
    category = try container.decodeIfPresent(String.self, forKey: .category)
    title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
    introduction = try container.decodeIfPresent(String.self, forKey: .introduction)
    description = try container.decodeIfPresent(String.self, forKey: .description)
    files = (try? container.decode([String].self, forKey: .files)) ?? []
    creator = try container.decodeIfPresent(FilterDetailUserDTO.self, forKey: .creator)
    metadata = try container.decodeIfPresent(FilterMetadataDTO.self, forKey: .metadata)
    filterValues = try container.decodeIfPresent(FilterValuesDTO.self, forKey: .filterValues)
    comments = (try? container.decode([FilterCommentDTO].self, forKey: .comments)) ?? []
    isDownloaded = try container.decodeFlexibleBool(forKey: .isDownloaded) ?? false
    isLiked = try container.decodeFlexibleBool(forKey: .isLiked) ?? false
    likeCount = try container.decodeFlexibleInt(forKey: .likeCount) ?? 0
    buyerCount = try container.decodeFlexibleInt(forKey: .buyerCount) ?? 0
    price = try container.decodeFlexibleInt(forKey: .price) ?? 0
    hashTags = (try? container.decode([String].self, forKey: .hashTags)) ?? []
    createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
  }

  private enum CodingKeys: String, CodingKey {
    case data
    case filterId
    case category
    case title
    case introduction
    case description
    case files
    case creator
    case metadata
    case filterValues
    case comments
    case isDownloaded
    case isLiked
    case likeCount
    case buyerCount
    case price
    case hashTags
    case createdAt
    case updatedAt
  }
}

nonisolated struct FilterDetailUserDTO: Decodable, Sendable {
  let userId: String
  let nick: String
  let name: String?
  let profileImage: String?
  let introduction: String?
  let hashTags: [String]?

  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    userId = try container.decodeFlexibleString(forKey: .userId) ?? ""
    nick = try container.decodeIfPresent(String.self, forKey: .nick) ?? ""
    name = try container.decodeIfPresent(String.self, forKey: .name)
    profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
    introduction = try container.decodeIfPresent(String.self, forKey: .introduction)
    hashTags = try container.decodeIfPresent([String].self, forKey: .hashTags)
  }

  private enum CodingKeys: String, CodingKey {
    case userId
    case nick
    case name
    case profileImage
    case introduction
    case hashTags
  }
}

nonisolated struct FilterMetadataDTO: Decodable, Sendable {
  let camera: String?
  let lens: String?
  let focalLength: String?
  let aperture: String?
  let shutterSpeed: String?
  let iso: String?
}

nonisolated struct FilterValuesDTO: Decodable, Sendable {
  let brightness: Double?
  let contrast: Double?
  let saturation: Double?
  let exposure: Double?
  let sharpen: Double?
  let blur: Double?
  let vignette: Double?
  let noiseReduction: Double?
  let highlights: Double?
  let shadows: Double?
  let temperature: Double?
  let tint: Double?
  let blackPoint: Double?
}

nonisolated struct FilterCommentDTO: Decodable, Sendable {
  let commentId: String
  let user: FilterDetailUserDTO?
  let content: String
  let createdAt: String?
  let replies: [FilterReplyDTO]

  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    commentId = try container.decodeFlexibleString(forKey: .commentId) ?? UUID().uuidString
    user = try container.decodeIfPresent(FilterDetailUserDTO.self, forKey: .user)
    content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
    createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    replies = (try? container.decode([FilterReplyDTO].self, forKey: .replies)) ?? []
  }

  private enum CodingKeys: String, CodingKey {
    case commentId
    case user
    case content
    case createdAt
    case replies
  }
}

nonisolated struct FilterReplyDTO: Decodable, Sendable {
  let replyId: String
  let user: FilterDetailUserDTO?
  let content: String
  let createdAt: String?

  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    replyId = try container.decodeFlexibleString(forKey: .replyId) ?? UUID().uuidString
    user = try container.decodeIfPresent(FilterDetailUserDTO.self, forKey: .user)
    content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
    createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
  }

  private enum CodingKeys: String, CodingKey {
    case replyId
    case user
    case content
    case createdAt
  }
}

private extension KeyedDecodingContainer {
  func decodeFlexibleString(forKey key: Key) throws -> String? {
    if let value = try decodeIfPresent(String.self, forKey: key) {
      return value
    }

    if let value = try decodeIfPresent(Int.self, forKey: key) {
      return String(value)
    }

    return nil
  }

  func decodeFlexibleInt(forKey key: Key) throws -> Int? {
    if let value = try decodeIfPresent(Int.self, forKey: key) {
      return value
    }

    if let value = try decodeIfPresent(String.self, forKey: key) {
      return Int(value)
    }

    return nil
  }

  func decodeFlexibleBool(forKey key: Key) throws -> Bool? {
    if let value = try decodeIfPresent(Bool.self, forKey: key) {
      return value
    }

    if let value = try decodeIfPresent(Int.self, forKey: key) {
      return value != 0
    }

    if let value = try decodeIfPresent(String.self, forKey: key) {
      return Bool(value)
    }

    return nil
  }
}
