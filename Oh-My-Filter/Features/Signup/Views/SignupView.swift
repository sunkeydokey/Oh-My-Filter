import SwiftUI
import Observation

struct SignupView: View {
  @Bindable var viewModel: SignupViewModel
  let onProfileLater: () -> Void
  let onProfileNow: () -> Void

  init(
    viewModel: SignupViewModel,
    onProfileLater: @escaping () -> Void = {},
    onProfileNow: @escaping () -> Void = {}
  ) {
    self.viewModel = viewModel
    self.onProfileLater = onProfileLater
    self.onProfileNow = onProfileNow
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 6) {
          Text("회원가입")
            .font(TypographyToken.pretendardTitle1.font)
            .foregroundStyle(ColorToken.grayScale0.color)

          Text("필수 정보를 입력하고 계정을 만들어 보세요.")
            .font(TypographyToken.pretendardCaption1.font)
            .foregroundStyle(ColorToken.grayScale60.color)
        }

        VStack(alignment: .leading, spacing: 10) {
          SignupTextFieldSection(
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

          SignupTextFieldSection(
            title: "비밀번호",
            description: "8자 이상, 영문자/숫자/특수문자를 각각 1개 이상 포함해야 해요.",
            message: viewModel.passwordErrorMessage
          ) {
            SecureField("••••••••", text: $viewModel.password)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
          }

          SignupTextFieldSection(
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

          SignupTextFieldSection(
            title: "닉네임",
            description: "닉네임에는 - . , ? * @ + ^ $ { } ( ) | [ ] \\ 문자를 사용할 수 없어요.",
            message: viewModel.nickErrorMessage
          ) {
            TextField("ohmyfilter_user", text: $viewModel.nick)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
          }

          SignupSubmitSection(
            isSubmitting: viewModel.isSubmitting,
            isEnabled: viewModel.canSubmit,
            message: viewModel.submissionMessage,
            submitAction: viewModel.submit
          )
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ColorToken.brandBlackSprout.color)
        .clipShape(.rect(cornerRadius: 15))
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
