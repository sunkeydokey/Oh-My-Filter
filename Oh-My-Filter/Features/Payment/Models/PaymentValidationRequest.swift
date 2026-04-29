import Foundation

nonisolated struct PaymentValidationRequest: Encodable, Equatable, Sendable {
  let impUid: String

  enum CodingKeys: String, CodingKey {
    case impUid = "imp_uid"
  }
}
