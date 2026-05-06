import AVFoundation
import Foundation

enum AuthenticatedVideoAssetBuilder {
  static func makeAsset(url: URL) async -> AVURLAsset {
    var headers: [String: String] = ["SeSACKey": Server.apiKey()]
    if let token = try? await AppTokenRefreshCoordinator.shared.authorizationHeaderValue() {
      headers["Authorization"] = token
    }
    return AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
  }
}
