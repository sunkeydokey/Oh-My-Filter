import Foundation
import Kingfisher

enum AuthenticatedRemoteImageSupport {
  static func url(from pathOrURLString: String?) -> URL? {
    guard let pathOrURLString, pathOrURLString.isEmpty == false else {
      return nil
    }

    if let url = URL(string: pathOrURLString), url.scheme != nil {
      return url
    }

    guard let baseURL = URL(string: Server.baseUrl()) else {
      return nil
    }

    let trimmedPath = pathOrURLString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    return baseURL.appending(path: trimmedPath)
  }

  static var requestModifier: any AsyncImageDownloadRequestModifier {
    AuthenticatedRemoteImageRequestModifier(
      tokenRefreshCoordinator: AppTokenRefreshCoordinator.shared
    )
  }
}

private struct AuthenticatedRemoteImageRequestModifier: AsyncImageDownloadRequestModifier {
  let tokenRefreshCoordinator: any TokenRefreshCoordinating
  let onDownloadTaskStarted: (@Sendable (DownloadTask?) -> Void)? = nil

  func modified(for request: URLRequest) async -> URLRequest? {
      var modifiedRequest = request
      modifiedRequest.setValue(Server.apiKey(), forHTTPHeaderField: "SeSACKey")

      if let accessToken = try? await tokenRefreshCoordinator.authorizationHeaderValue() {
        modifiedRequest.setValue(accessToken, forHTTPHeaderField: "Authorization")
      }

      return modifiedRequest
  }
}
