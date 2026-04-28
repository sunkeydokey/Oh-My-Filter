import AuthenticationServices
import Observation
import SwiftUI

struct LoginView: View {
  @Bindable var viewModel: LoginViewModel
  let onSignupTap: () -> Void

  init(
    viewModel: LoginViewModel,
    onSignupTap: @escaping () -> Void = {}
  ) {
    self.viewModel = viewModel
    self.onSignupTap = onSignupTap
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        AuthHeaderView(
          title: "로그인",
          subtitle: nil
        )

        VStack(alignment: .leading, spacing: 8) {
          Text("필터 너머의 취향을 연결해요")
            .font(TypographyToken.mulgyeolTitle1.font)
            .foregroundStyle(ColorToken.grayScale0.color)

          Text("차분한 시작으로, 나에게 맞는 필터 경험을 이어가세요.")
            .font(TypographyToken.pretendardBody2.font)
            .foregroundStyle(ColorToken.grayScale60.color)
        }

        AuthCard {
          AuthFieldSection(title: "이메일") {
            TextField(
              "you@example.com",
              text: Binding(
                get: { viewModel.state.email },
                set: { viewModel.send(.emailChanged($0)) }
              )
            )
              .keyboardType(.emailAddress)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
          }

          AuthFieldSection(title: "비밀번호") {
            SecureField(
              "••••••••",
              text: Binding(
                get: { viewModel.state.password },
                set: { viewModel.send(.passwordChanged($0)) }
              )
            )
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
          }

          AuthSubmitSection(
            title: "로그인",
            isSubmitting: viewModel.state.isSubmitting,
            isEnabled: viewModel.state.canSubmit,
            message: viewModel.state.submissionMessage,
            submitAction: {
              if let task = viewModel.send(.submitTapped) {
                await task.value
              }
            }
          )
        }

        VStack(spacing: 10) {
          AuthSocialLoginButton(
            title: "카카오 로그인",
            systemImage: IconToken.chat.symbolName,
            font: TypographyToken.pretendardTitle1.font,
            fillColor: Color(red: 254 / 255, green: 229 / 255, blue: 0),
            foregroundColor: .black,
            action: {
              if let task = viewModel.send(.kakaoLoginTapped) {
                await task.value
              }
            }
          )

          SignInWithAppleButton(.continue) { request in
            viewModel.send(.appleLoginStarted)
            request.requestedScopes = [.email, .fullName]
          } onCompletion: { result in
            switch result {
            case let .success(authorization):
              let credential = authorization.credential as? ASAuthorizationAppleIDCredential
              viewModel.send(.appleLoginCompleted(identityToken: credential?.identityToken))
            case .failure:
              viewModel.send(.appleLoginFailed)
            }
          }
          .signInWithAppleButtonStyle(.whiteOutline)
          .frame(maxWidth: .infinity, minHeight: 48)
          .clipShape(.rect(cornerRadius: CornerRadiusToken.section.value))
          .disabled(viewModel.state.isSubmitting)
        }

        AuthNavigationPromptView(
          prompt: "계정이 없나요?",
          actionTitle: "회원가입",
          action: onSignupTap
        )
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 28)
    }
    .scrollIndicators(.hidden)
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
  }
}
