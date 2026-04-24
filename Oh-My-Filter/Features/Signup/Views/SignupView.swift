import SwiftUI
import Observation

struct SignupView: View {
  @Bindable var viewModel: SignupViewModel
  let onLoginTap: () -> Void
  let onProfileLater: () -> Void
  let onProfileNow: () -> Void

  init(
    viewModel: SignupViewModel,
    onLoginTap: @escaping () -> Void = {},
    onProfileLater: @escaping () -> Void = {},
    onProfileNow: @escaping () -> Void = {}
  ) {
    self.viewModel = viewModel
    self.onLoginTap = onLoginTap
    self.onProfileLater = onProfileLater
    self.onProfileNow = onProfileNow
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        AuthHeaderView(
          title: "회원가입",
          subtitle: "필수 정보를 입력하고 계정을 만들어 보세요."
        )

        AuthCard {
          AuthFieldSection(
            title: "이메일",
            message: viewModel.state.emailErrorMessage ?? viewModel.state.emailSuccessMessage,
            isSuccess: viewModel.state.emailSuccessMessage != nil
          ) {
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

          if case .checking = viewModel.state.emailCheckState {
            ProgressView("이메일 확인 중…")
              .font(TypographyToken.pretendardCaption1.font)
              .foregroundStyle(ColorToken.grayScale60.color)
          }

          AuthFieldSection(
            title: "비밀번호",
            description: "8자 이상, 영문자/숫자/특수문자를 각각 1개 이상 포함해야 해요.",
            message: viewModel.state.passwordErrorMessage
          ) {
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

          AuthFieldSection(
            title: "비밀번호 확인",
            description: viewModel.state.passwordConfirmationErrorMessage == nil
              ? "비밀번호가 일치하는지 확인해 주세요."
              : nil,
            message: viewModel.state.passwordConfirmationErrorMessage,
            isSuccess: viewModel.state.isPasswordConfirmationSuccess
          ) {
            SecureField(
              "••••••••",
              text: Binding(
                get: { viewModel.state.passwordConfirmation },
                set: { viewModel.send(.passwordConfirmationChanged($0)) }
              )
            )
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
          }

          AuthFieldSection(
            title: "닉네임",
            description: "닉네임에는 - . , ? * @ + ^ $ { } ( ) | [ ] \\ 문자를 사용할 수 없어요.",
            message: viewModel.state.nickErrorMessage
          ) {
            TextField(
              "ohmyfilter_user",
              text: Binding(
                get: { viewModel.state.nick },
                set: { viewModel.send(.nickChanged($0)) }
              )
            )
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
          }

          AuthSubmitSection(
            title: "회원가입",
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

        AuthNavigationPromptView(
          prompt: "이미 계정이 있나요?",
          actionTitle: "로그인",
          action: onLoginTap
        )
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 24)
    }
    .scrollIndicators(.hidden)
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
    .overlay {
      if viewModel.state.isShowingSignupCompletionAlert {
        CustomAlertView(
          title: "회원가입이 완료되었습니다!",
          message: "프로필을 작성할까요?",
          cancelTitle: "나중에 할래요",
          confirmTitle: "지금 할래요",
          onCancel: {
            viewModel.send(.completionAlertDismissed)
            onProfileLater()
          },
          onConfirm: {
            viewModel.send(.completionAlertDismissed)
            onProfileNow()
          }
        )
      }
    }
  }
}
