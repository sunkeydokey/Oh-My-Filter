import Foundation

enum LoginAction: Equatable, Sendable {
  case emailChanged(String)
  case passwordChanged(String)
  case submitTapped
}
