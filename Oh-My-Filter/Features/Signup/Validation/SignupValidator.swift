import Foundation

enum SignupValidator {
  private static let emailPattern = /^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
  private static let passwordPattern = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$/
  private static let forbiddenNicknameCharacters = CharacterSet(charactersIn: "-.,?*@+^${}()|[]\\")

  static func isValidEmail(_ email: String) -> Bool {
    normalized(email).wholeMatch(of: emailPattern) != nil
  }

  static func passwordErrorMessage(for password: String) -> String? {
    let normalizedPassword = normalized(password)

    guard normalizedPassword.isEmpty == false else {
      return nil
    }

    guard normalizedPassword.count >= 8 else {
      return "비밀번호는 8자 이상이어야 해요."
    }

    guard normalizedPassword.wholeMatch(of: passwordPattern) != nil else {
      return "영문자, 숫자, 특수문자(@$!%*#?&)를 각각 1개 이상 포함해 주세요."
    }

    return nil
  }

  static func passwordConfirmationErrorMessage(
    password: String,
    confirmation: String
  ) -> String? {
    let normalizedConfirmation = normalized(confirmation)

    guard normalizedConfirmation.isEmpty == false else {
      return nil
    }

    guard normalized(password) == normalizedConfirmation else {
      return "비밀번호가 일치하지 않아요."
    }

    return nil
  }

  static func nickErrorMessage(for nick: String) -> String? {
    let normalizedNick = normalized(nick)

    guard normalizedNick.isEmpty == false else {
      return nil
    }

    guard normalizedNick.rangeOfCharacter(from: forbiddenNicknameCharacters) == nil else {
      return "닉네임에는 - . , ? * @ + ^ $ { } ( ) | [ ] \\ 문자를 사용할 수 없어요."
    }

    return nil
  }

  static func normalized(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
