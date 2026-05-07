import Foundation

nonisolated struct MyProfileResponseDTO: Decodable, Equatable, Sendable {
  let userId: String
  let email: String
  let nick: String
  let name: String?
  let introduction: String?
  let profileImage: String?
  let phoneNum: String?
  let hashTags: [String]

  nonisolated init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if let wrapped = try container.decodeIfPresent(MyProfileResponseDTO.self, forKey: .data) {
      self = wrapped
      return
    }

    userId = try container.decode(String.self, forKey: .userId)
    email = try container.decode(String.self, forKey: .email)
    nick = try container.decode(String.self, forKey: .nick)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    introduction = try container.decodeIfPresent(String.self, forKey: .introduction)
    profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
    phoneNum = try container.decodeIfPresent(String.self, forKey: .phoneNum)
    hashTags = try container.decodeIfPresent([String].self, forKey: .hashTags) ?? []
  }

  private enum CodingKeys: String, CodingKey {
    case data
    case userId
    case email
    case nick
    case name
    case introduction
    case profileImage
    case phoneNum
    case hashTags
  }
}

nonisolated struct OrderHistoryResponseDTO: Decodable, Equatable, Sendable {
  let data: [OrderHistoryItemDTO]
}

nonisolated struct OrderHistoryItemDTO: Decodable, Equatable, Sendable {
  let orderId: String
  let orderCode: String
  let filter: OrderHistoryFilterDTO
  let paidAt: String
}

nonisolated struct OrderHistoryFilterDTO: Decodable, Equatable, Sendable {
  let id: String?
  let category: String
  let title: String
  let description: String
  let files: [String]
  let price: Int
  let creator: OrderHistoryCreatorDTO
}

nonisolated struct OrderHistoryCreatorDTO: Decodable, Equatable, Sendable {
  let userId: String
  let nick: String
  let name: String?
  let introduction: String?
  let profileImage: String?
  let hashTags: [String]
}
