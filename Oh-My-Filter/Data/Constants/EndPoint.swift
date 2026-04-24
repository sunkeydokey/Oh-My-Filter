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
}
