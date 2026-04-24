import Foundation

struct NetworkResponse: Sendable {
  let data: Data
  let statusCode: Int
}
