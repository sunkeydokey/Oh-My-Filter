import Foundation

nonisolated struct MyProfile: Equatable, Sendable {
  let userID: String
  let email: String
  let nick: String
  let name: String?
  let introduction: String?
  let profileImage: String?
  let phoneNumber: String?
  let hashTags: [String]

  var displayName: String {
    if let name, name.isEmpty == false {
      return name
    }
    return nick
  }

  var avatarInitials: String {
    String(displayName.prefix(2)).uppercased()
  }
}

nonisolated struct ProfileUpdateDraft: Equatable, Sendable {
  var nick: String
  var name: String
  var introduction: String
  var phoneNumber: String
  var profileImage: String?
  var hashTags: [String]

  init(profile: MyProfile) {
    nick = profile.nick
    name = profile.name ?? ""
    introduction = profile.introduction ?? ""
    phoneNumber = profile.phoneNumber ?? ""
    profileImage = profile.profileImage
    hashTags = profile.hashTags
  }
}

nonisolated struct ProfileUpdateRequest: Encodable, Equatable, Sendable {
  let nick: String?
  let name: String?
  let introduction: String?
  let phoneNum: String?
  let profileImage: String?
  let hashTags: [String]?
}

nonisolated struct ProfileImageUploadResponse: Decodable, Equatable, Sendable {
  let profileImage: String?
}

nonisolated struct OrderHistoryItem: Equatable, Identifiable, Sendable {
  let id: String
  let orderCode: String
  let filter: OrderHistoryFilter
  let paidAt: Date
}

nonisolated struct OrderHistoryFilter: Equatable, Hashable, Identifiable, Sendable {
  let id: String
  let category: String
  let title: String
  let description: String
  let files: [String]
  let price: Int
  let creator: OrderHistoryCreator
}

nonisolated struct OrderHistoryCreator: Equatable, Hashable, Identifiable, Sendable {
  let id: String
  let nick: String
  let name: String?
  let introduction: String?
  let profileImage: String?
  let hashTags: [String]
}
