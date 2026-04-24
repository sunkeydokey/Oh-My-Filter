import Foundation

enum NetworkError: Error, Equatable, Sendable {
  case invalidRequest
  case invalidResponse
  case transport
}
