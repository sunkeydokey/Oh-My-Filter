import Foundation

nonisolated struct PortonePaymentRequest: Equatable, Identifiable, Sendable {
  let id: String
  let postID: String
  let pgCode: String
  let payMethod: String
  let merchantUID: String
  let amount: String
  let name: String
  let buyerName: String
  let appScheme: String

  init(detail: FilterDetail, merchantUID: String) {
    id = detail.id
    postID = detail.id
    pgCode = SDK.Payment.pgCode
    payMethod = "card"
    self.merchantUID = merchantUID
    amount = "\(detail.price)"
    name = detail.title
    buyerName = SDK.Payment.buyerName
    appScheme = SDK.Payment.appScheme
  }
}
