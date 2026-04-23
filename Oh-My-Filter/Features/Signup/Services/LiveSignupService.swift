import Foundation

struct LiveSignupService: SignupServicing {
  private let session: URLSession
  private let encoder: JSONEncoder

  init(
    session: URLSession = .shared,
    encoder: JSONEncoder = JSONEncoder()
  ) {
    self.session = session
    self.encoder = encoder
  }

  func validateEmail(_ email: String) async throws -> EmailValidationStatus {
    let requestBody = EmailValidationRequest(email: email)
    let request = try makeRequest(
      path: "users/validation/email",
      body: requestBody
    )

    do {
      let (_, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw SignupServiceError.invalidResponse
      }

      switch httpResponse.statusCode {
      case 200 ..< 300:
        return .available
      case 400:
        return .invalid
      case 409:
        return .duplicate
      default:
        throw SignupServiceError.serverError
      }
    } catch let error as SignupServiceError {
      throw error
    } catch {
      throw SignupServiceError.transport
    }
  }

  func join(request: SignupRequest) async throws {
    let request = try makeRequest(path: "users/join", body: request)

    do {
      let (_, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse else {
        throw SignupServiceError.invalidResponse
      }

      switch httpResponse.statusCode {
      case 200 ..< 300:
        return
      case 400:
        throw SignupServiceError.invalidRequest
      case 409:
        throw SignupServiceError.duplicateEmail
      default:
        throw SignupServiceError.serverError
      }
    } catch let error as SignupServiceError {
      throw error
    } catch {
      throw SignupServiceError.transport
    }
  }

  private func makeRequest<T: Encodable>(path: String, body: T) throws -> URLRequest {
    guard let url = URL(string: Server.baseUrl())?.appending(path: path) else {
      throw SignupServiceError.invalidRequest
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue(Server.apiKey(), forHTTPHeaderField: "SeSACKey")
    request.httpBody = try encoder.encode(body)
    return request
  }
}

private struct EmailValidationRequest: Encodable, Sendable {
  let email: String
}
