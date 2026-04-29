import Foundation

nonisolated enum PaymentApiRouter: ApiRouter {
  case validation

  var url: String {
    switch self {
    case .validation:
      EndPoint.Payment.validation
    }
  }

  var method: HttpMethod {
    .post
  }

  var contentType: ContentType {
    .json
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
