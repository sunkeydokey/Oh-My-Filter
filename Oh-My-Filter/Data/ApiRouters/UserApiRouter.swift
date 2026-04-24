//
//  UserApiRouter.swift
//  Oh-My-Filter
//
//  Created by 이선기 on 4/24/26.
//

import Foundation

nonisolated enum UserApiRouter: ApiRouter {
  case validate
  case signUp
  case signIn
  case kakaoLogin
  case appleLogin
  case logout
  case updateDeviceToken
  case getUserInfo(userId: String)
  case uploadProfileImage
  case getOwnProfile
  case editUserProfile
  case getTodayAuthorInfo
  case searchUser

  var url: String {
    switch self {
    case .validate:
      EndPoint.User.validateEmail
    case .signUp:
      EndPoint.User.signUp
    case .signIn:
      EndPoint.User.signIn
    case .kakaoLogin:
      EndPoint.User.kakaoSignIn
    case .appleLogin:
      EndPoint.User.appleSignIn
    case .logout:
      EndPoint.User.logout
    case .updateDeviceToken:
      EndPoint.User.updateDeviceToken
    case .getUserInfo(let userId):
      EndPoint.User.getUserProfile(userId: userId)
    case .uploadProfileImage:
      EndPoint.User.uploadProfileImage
    case .getOwnProfile, .editUserProfile:
      EndPoint.User.ownProfile
    case .getTodayAuthorInfo:
      EndPoint.User.getTodayAuthor
    case .searchUser:
      EndPoint.User.searchUser
    }
  }

  var method: HttpMethod {
    switch self {
    case .validate, .signUp, .signIn, .kakaoLogin, .appleLogin, .logout, .uploadProfileImage:
      .post
    case .getOwnProfile, .getUserInfo, .getTodayAuthorInfo, .searchUser:
      .get
    case .updateDeviceToken, .editUserProfile:
      .put
    }
  }

  var contentType: ContentType {
    switch self {
    case .uploadProfileImage:
      .multipart
    default:
      .json
    }
  }
}
