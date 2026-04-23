import Testing
@testable import Oh_My_Filter

struct SignupValidatorTests {
  @Test("valid email passes")
  func validEmailPasses() {
    #expect(SignupValidator.isValidEmail("sesac@sesac.com"))
  }

  @Test("invalid email fails")
  func invalidEmailFails() {
    #expect(SignupValidator.isValidEmail("sesac@sesac") == false)
  }

  @Test("password needs all required categories")
  func passwordRules() {
    #expect(SignupValidator.passwordErrorMessage(for: "abcd1234@") == nil)
    #expect(SignupValidator.passwordErrorMessage(for: "abcd1234") != nil)
    #expect(SignupValidator.passwordErrorMessage(for: "abcd@@@@") != nil)
    #expect(SignupValidator.passwordErrorMessage(for: "1234@@@@") != nil)
    #expect(SignupValidator.passwordErrorMessage(for: "a1@") != nil)
  }

  @Test("password confirmation must match")
  func passwordConfirmationRules() {
    #expect(
      SignupValidator.passwordConfirmationErrorMessage(
        password: "abcd1234@",
        confirmation: " abcd1234@ "
      ) == nil
    )
    #expect(
      SignupValidator.passwordConfirmationErrorMessage(
        password: "abcd1234@",
        confirmation: "other1234@"
      ) == "비밀번호가 일치하지 않아요."
    )
  }

  @Test("nickname rejects forbidden characters")
  func nicknameRejectsForbiddenCharacters() {
    #expect(SignupValidator.nickErrorMessage(for: "새싹이Abc12") == nil)
    #expect(SignupValidator.nickErrorMessage(for: "bad-name") != nil)
    #expect(SignupValidator.nickErrorMessage(for: "bad@name") != nil)
    #expect(SignupValidator.nickErrorMessage(for: "bad\\name") != nil)
  }
}
