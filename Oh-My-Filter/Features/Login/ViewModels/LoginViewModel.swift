import Foundation
import Observation

@MainActor
@Observable
final class LoginViewModel {
  var state = LoginState()

  private let service: LoginServicing
  private let kakaoOAuthProvider: KakaoOAuthProviding
  var onLoginSucceeded: @MainActor (LoginSession) -> Void

  init(
    service: LoginServicing,
    kakaoOAuthProvider: KakaoOAuthProviding,
    onLoginSucceeded: @escaping @MainActor (LoginSession) -> Void = { _ in }
  ) {
    self.service = service
    self.kakaoOAuthProvider = kakaoOAuthProvider
    self.onLoginSucceeded = onLoginSucceeded
  }

  convenience init(
    service: LoginServicing,
    onLoginSucceeded: @escaping @MainActor (LoginSession) -> Void = { _ in }
  ) {
    self.init(
      service: service,
      kakaoOAuthProvider: LiveKakaoOAuthProvider(),
      onLoginSucceeded: onLoginSucceeded
    )
  }

  @discardableResult
  func send(_ action: LoginAction) -> Task<Void, Never>? {
    switch action {
    case let .emailChanged(email):
      state.email = email
      state.submissionMessage = nil
      return nil
    case let .passwordChanged(password):
      state.password = password
      state.submissionMessage = nil
      return nil
    case .submitTapped:
      return submit()
    case .kakaoLoginTapped:
      return submitWithKakao()
    case .appleLoginStarted:
      state.submissionMessage = nil
      state.isSubmitting = true
      return nil
    case let .appleLoginCompleted(identityToken):
      return submitWithApple(identityToken: identityToken)
    case .appleLoginFailed:
      state.submissionMessage = "로그인 중 문제가 발생했어요. 다시 시도해 주세요."
      state.isSubmitting = false
      return nil
    }
  }

  private func submit() -> Task<Void, Never>? {
    state.submissionMessage = nil

    guard state.canSubmit else {
      state.submissionMessage = "필수값을 채워주세요."
      return nil
    }

    state.isSubmitting = true
    let request = state.loginRequest

    return Task {
      do {
        let session = try await service.login(request: request)
        state.isSubmitting = false
        onLoginSucceeded(session)
      } catch let error as LoginServiceError {
        state.submissionMessage = error.errorDescription
        state.isSubmitting = false
      } catch {
        state.submissionMessage = "로그인 중 문제가 발생했어요. 다시 시도해 주세요."
        state.isSubmitting = false
      }
    }
  }

  private func submitWithKakao() -> Task<Void, Never>? {
    guard state.isSubmitting == false else { return nil }

    state.submissionMessage = nil
    state.isSubmitting = true

    return Task {
      do {
        let accessToken = try await kakaoOAuthProvider.accessToken()
        let session = try await service.loginWithKakao(
          request: KakaoLoginRequest(oauthToken: accessToken)
        )
        state.isSubmitting = false
        onLoginSucceeded(session)
      } catch let error as LoginServiceError {
        state.submissionMessage = error.errorDescription
        state.isSubmitting = false
      } catch {
        state.submissionMessage = "로그인 중 문제가 발생했어요. 다시 시도해 주세요."
        state.isSubmitting = false
      }
    }
  }

  private func submitWithApple(identityToken: Data?) -> Task<Void, Never>? {
    guard
      let identityToken,
      let idToken = String(data: identityToken, encoding: .utf8),
      idToken.isEmpty == false
    else {
      state.submissionMessage = "Apple 로그인 정보를 확인할 수 없어요. 다시 시도해 주세요."
      state.isSubmitting = false
      return nil
    }

    state.submissionMessage = nil
    state.isSubmitting = true

    return Task {
      do {
        let session = try await service.loginWithApple(
          request: AppleLoginRequest(idToken: idToken)
        )
        state.isSubmitting = false
        onLoginSucceeded(session)
      } catch let error as LoginServiceError {
        state.submissionMessage = error.errorDescription
        state.isSubmitting = false
      } catch {
        state.submissionMessage = "로그인 중 문제가 발생했어요. 다시 시도해 주세요."
        state.isSubmitting = false
      }
    }
  }
}
