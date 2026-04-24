import Foundation

enum SignupAction: Equatable, Sendable {
  case emailChanged(String)
  case passwordChanged(String)
  case passwordConfirmationChanged(String)
  case nickChanged(String)
  case submitTapped
  case completionAlertDismissed
}
