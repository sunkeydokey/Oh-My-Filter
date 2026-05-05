//
//  EndPoint.swift
//  Oh-My-Filter
//
//  Created by 이선기 on 4/23/26.
//

import Foundation

nonisolated enum EndPoint {
  private static let baseUrl = Server.baseUrl()

  nonisolated enum Auth {
    static let refresh = "\(EndPoint.baseUrl)/auth/refresh"
  }

  nonisolated enum User {
    static let validateEmail = "\(EndPoint.baseUrl)/users/validation/email"
    static let signUp = "\(EndPoint.baseUrl)/users/join"
    static let signIn = "\(EndPoint.baseUrl)/users/login"
    static let kakaoSignIn = "\(EndPoint.baseUrl)/users/login/kakao"
    static let appleSignIn = "\(EndPoint.baseUrl)/users/login/apple"
    static let logout = "\(EndPoint.baseUrl)/users/logout"

    static let updateDeviceToken = "\(EndPoint.baseUrl)/users/deviceToken"

    static func getUserProfile(userId: String) -> String {
      return "\(EndPoint.baseUrl)/users/\(userId)/profile"
    }

    static let uploadProfileImage = "\(EndPoint.baseUrl)/users/profile/image"

    static let ownProfile = "\(EndPoint.baseUrl)/users/me/profile"

    static let getTodayAuthor = "\(EndPoint.baseUrl)/users/today-author"

    static let searchUser = "\(EndPoint.baseUrl)/users/search"
  }

  nonisolated enum Filters {
    static let list = "\(EndPoint.baseUrl)/filters"
    static let files = "\(EndPoint.baseUrl)/filters/files"
    static let today = "\(EndPoint.baseUrl)/filters/today-filter"
    static let hotTrend = "\(EndPoint.baseUrl)/filters/hot-trend"

    static func detail(filterID: String) -> String {
      "\(EndPoint.baseUrl)/filters/\(filterID)"
    }
  }

  nonisolated enum Posts {
    static let create = "\(EndPoint.baseUrl)/posts"
    static let files = "\(EndPoint.baseUrl)/posts/files"
    static let geolocation = "\(EndPoint.baseUrl)/posts/geolocation"
    static let search = "\(EndPoint.baseUrl)/posts/search"
    static let likedMe = "\(EndPoint.baseUrl)/posts/likes/me"

    static func detail(postID: String) -> String {
      "\(EndPoint.baseUrl)/posts/\(postID)"
    }

    static func like(postID: String) -> String {
      "\(EndPoint.baseUrl)/posts/\(postID)/like"
    }

    static func comments(postID: String) -> String {
      "\(EndPoint.baseUrl)/posts/\(postID)/comments"
    }
  }

  nonisolated enum Videos {
    static let list = "\(EndPoint.baseUrl)/videos"

    static func stream(videoId: String) -> String {
      "\(EndPoint.baseUrl)/videos/\(videoId)/stream"
    }

    static func like(videoId: String) -> String {
      "\(EndPoint.baseUrl)/videos/\(videoId)/like"
    }
  }

  nonisolated enum Banners {
    static let main = "\(EndPoint.baseUrl)/banners/main"
  }

  nonisolated enum Payment {
    static let validation = "\(EndPoint.baseUrl)/payments/validation"
  }

  nonisolated enum Orders {
    static let create = "\(EndPoint.baseUrl)/orders"
  }

  nonisolated enum Chats {
    static let rooms = "\(EndPoint.baseUrl)/chats"

    static func room(roomID: String) -> String {
      "\(EndPoint.baseUrl)/chats/\(roomID)"
    }

    static func files(roomID: String) -> String {
      "\(EndPoint.baseUrl)/chats/\(roomID)/files"
    }
  }
}
