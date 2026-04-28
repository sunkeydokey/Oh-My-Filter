import ImageIO
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import Oh_My_Filter

@MainActor
struct LoginViewSnapshotTests {
  @Test("Login view renders a snapshot")
  func rendersSnapshot() throws {
    let viewModel = LoginViewModel(service: SnapshotLoginService())
    let view = LoginView(
      viewModel: viewModel,
      onSignupTap: {}
    )
    .frame(width: 390, height: 844)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 1

    let snapshotURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appending(path: "login-view.png")

    guard let cgImage = renderer.cgImage else {
      Issue.record("Failed to render login view snapshot")
      return
    }

    guard let destination = CGImageDestinationCreateWithURL(
      snapshotURL as CFURL,
      UTType.png.identifier as CFString,
      1,
      nil
    ) else {
      Issue.record("Failed to create login snapshot destination")
      return
    }

    CGImageDestinationAddImage(destination, cgImage, nil)
    #expect(CGImageDestinationFinalize(destination))
    #expect(FileManager.default.fileExists(atPath: snapshotURL.path()))
    print("LoginView snapshot: \(snapshotURL.path())")
  }
}

private actor SnapshotLoginService: LoginServicing {
  func login(request: LoginRequest) async throws -> LoginSession {
    .fixture
  }

  func loginWithKakao(request: KakaoLoginRequest) async throws -> LoginSession {
    .fixture
  }
}

private extension LoginSession {
  static let fixture = LoginSession(
    userID: "66115b1197488f90d3e7e6e5",
    email: "sesac@sesac.com",
    nick: "새싹이Abc12",
    profileImage: "/data/profiles/1712413657554.png"
  )
}
