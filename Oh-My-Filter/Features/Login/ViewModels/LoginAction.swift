import Foundation

enum LoginAction: Equatable, Sendable {
  case emailChanged(String)
  case passwordChanged(String)
  case submitTapped
  case kakaoLoginTapped
  case appleLoginStarted
  case appleLoginCompleted(identityToken: Data?)
  case appleLoginFailed
}
