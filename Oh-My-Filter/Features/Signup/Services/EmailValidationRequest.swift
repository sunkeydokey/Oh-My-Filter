import Foundation

struct EmailValidationRequest: Encodable, Sendable {
  let email: String
}
