import Foundation
import KakaoSDKAuth
import KakaoSDKUser

struct LiveKakaoOAuthProvider: KakaoOAuthProviding {
  func accessToken() async throws -> String {
    let token = if UserApi.isKakaoTalkLoginAvailable() {
      try await loginWithKakaoTalk()
    } else {
      try await loginWithKakaoAccount()
    }

    return token.accessToken
  }

  private func loginWithKakaoTalk() async throws -> OAuthToken {
    try await withCheckedThrowingContinuation { continuation in
      UserApi.shared.loginWithKakaoTalk { token, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }

        guard let token else {
          continuation.resume(throwing: KakaoOAuthProviderError.missingToken)
          return
        }

        continuation.resume(returning: token)
      }
    }
  }

  private func loginWithKakaoAccount() async throws -> OAuthToken {
    try await withCheckedThrowingContinuation { continuation in
      UserApi.shared.loginWithKakaoAccount { token, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }

        guard let token else {
          continuation.resume(throwing: KakaoOAuthProviderError.missingToken)
          return
        }

        continuation.resume(returning: token)
      }
    }
  }
}

private enum KakaoOAuthProviderError: Error, Sendable {
  case missingToken
}
