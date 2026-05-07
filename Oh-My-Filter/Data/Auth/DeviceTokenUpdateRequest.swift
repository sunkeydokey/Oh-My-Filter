import Foundation

nonisolated struct DeviceTokenUpdateRequest: Encodable, Equatable, Sendable {
  let deviceToken: String
}
