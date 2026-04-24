import Foundation

protocol SignupServicing: Sendable {
  func validateEmail(_ email: String) async throws -> EmailValidationStatus
  func join(request: SignupRequest) async throws
}
