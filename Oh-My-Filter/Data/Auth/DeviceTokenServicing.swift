import Foundation

nonisolated protocol DeviceTokenServicing: Sendable {
  func updateDeviceToken(_ token: String) async throws
}

nonisolated struct LiveDeviceTokenService: DeviceTokenServicing {
  private let networkManager: any AuthenticatedNetworkManaging

  init(networkManager: any AuthenticatedNetworkManaging) {
    self.networkManager = networkManager
  }

  @MainActor
  init() {
    self.init(networkManager: AuthenticatedNetworkManager())
  }

  func updateDeviceToken(_ token: String) async throws {
    let response = try await networkManager.request(
      UserApiRouter.updateDeviceToken,
      body: DeviceTokenUpdateRequest(deviceToken: token)
    )

    guard 200 ..< 300 ~= response.statusCode else {
      throw DeviceTokenServiceError.updateFailed
    }
  }
}

nonisolated enum DeviceTokenServiceError: Error, Equatable, Sendable {
  case updateFailed
}
