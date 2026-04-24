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
            message: viewModel.emailErrorMessage ?? viewModel.emailSuccessMessage,
            isSuccess: viewModel.emailSuccessMessage != nil
          ) {
            TextField("you@example.com", text: $viewModel.email)
              .keyboardType(.emailAddress)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .onChange(of: viewModel.email, initial: false) { oldValue, newValue in
                viewModel.emailChanged(from: oldValue, to: newValue)
              }
          }

          if case .checking = viewModel.emailCheckState {
            ProgressView("이메일 확인 중…")
              .font(TypographyToken.pretendardCaption1.font)
              .foregroundStyle(ColorToken.grayScale60.color)
          }

          AuthFieldSection(
            title: "비밀번호",
            description: "8자 이상, 영문자/숫자/특수문자를 각각 1개 이상 포함해야 해요.",
            message: viewModel.passwordErrorMessage
          ) {
            SecureField("••••••••", text: $viewModel.password)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
          }

          AuthFieldSection(
            title: "비밀번호 확인",
            description: viewModel.passwordConfirmationErrorMessage == nil
              ? "비밀번호가 일치하는지 확인해 주세요."
              : nil,
            message: viewModel.passwordConfirmationErrorMessage,
            isSuccess: viewModel.passwordConfirmationErrorMessage == nil
              && SignupValidator.normalized(viewModel.passwordConfirmation).isEmpty == false
          ) {
            SecureField("••••••••", text: $viewModel.passwordConfirmation)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
          }

          AuthFieldSection(
            title: "닉네임",
            description: "닉네임에는 - . , ? * @ + ^ $ { } ( ) | [ ] \\ 문자를 사용할 수 없어요.",
            message: viewModel.nickErrorMessage
          ) {
            TextField("ohmyfilter_user", text: $viewModel.nick)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
          }

          AuthSubmitSection(
            title: "회원가입",
            isSubmitting: viewModel.isSubmitting,
            isEnabled: viewModel.canSubmit,
            message: viewModel.submissionMessage,
            submitAction: viewModel.submit
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
      if viewModel.isShowingSignupCompletionAlert {
        CustomAlertView(
          title: "회원가입이 완료되었습니다!",
          message: "프로필을 작성할까요?",
          cancelTitle: "나중에 할래요",
          confirmTitle: "지금 할래요",
          onCancel: onProfileLater,
          onConfirm: onProfileNow
        )
      }
    }
  }
}
