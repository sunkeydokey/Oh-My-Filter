import Foundation

nonisolated struct NetworkResponse: Sendable {
  let data: Data
  let statusCode: Int
}
