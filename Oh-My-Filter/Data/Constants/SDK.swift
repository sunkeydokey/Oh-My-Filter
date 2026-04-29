import Foundation
import iamport_ios

nonisolated enum SDK {
  nonisolated enum Payment {
    static let appScheme = "ohmyfilterpayment"
    static var userCode: String {
      guard let code = Bundle.main.object(forInfoDictionaryKey: "PAYMENT_USER_CODE") as? String,
            code.isEmpty == false
      else {
        return ""
      }

      return code
    }

    static let pgCode = PG.html5_inicis.makePgRawName(pgId: "INIpayTest")

    static var buyerName: String {
      guard let name = Bundle.main.object(forInfoDictionaryKey: "REAL_NAME") as? String,
            name.isEmpty == false
      else {
        return ""
      }

      return name
    }

    static var pgId: String {
      guard let id = Bundle.main.object(forInfoDictionaryKey: "PG_ID") as? String,
            id.isEmpty == false
      else {
        return ""
      }

      return id
    }
  }
}
