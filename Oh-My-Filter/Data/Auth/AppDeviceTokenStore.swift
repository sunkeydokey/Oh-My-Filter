import Foundation

nonisolated protocol DeviceTokenStoring: Sendable {
  func deviceToken() -> String?
  func saveDeviceToken(_ token: String)
}

nonisolated struct AppDeviceTokenStore: DeviceTokenStoring, @unchecked Sendable {
  private let defaults: UserDefaults
  private let key: String

  init(
    defaults: UserDefaults = .standard,
    key: String = "app.deviceToken"
  ) {
    self.defaults = defaults
    self.key = key
  }

  func deviceToken() -> String? {
    defaults.string(forKey: key)
  }

  func saveDeviceToken(_ token: String) {
    defaults.set(token, forKey: key)
  }
}
