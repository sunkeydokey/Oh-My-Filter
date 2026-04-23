import Foundation

enum EmailValidationStatus: Equatable, Sendable {
  case available
  case invalid
  case duplicate
}

enum EmailCheckState: Equatable, Sendable {
  case idle
  case invalidFormat(String)
  case checking
  case available(String)
  case invalid(String)
  case duplicate(String)
  case failed(String)

  var message: String? {
    switch self {
    case .idle, .checking:
      nil
    case let .invalidFormat(message),
      let .available(message),
      let .invalid(message),
      let .duplicate(message),
      let .failed(message):
      message
    }
  }

  var isSuccess: Bool {
    if case .available = self {
      true
    } else {
      false
    }
  }
}
