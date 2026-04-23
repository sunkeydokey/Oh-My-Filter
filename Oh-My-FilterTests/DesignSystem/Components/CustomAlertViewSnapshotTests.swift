import ImageIO
import SwiftUI
import Testing
import UniformTypeIdentifiers
@testable import Oh_My_Filter

@MainActor
struct CustomAlertViewSnapshotTests {
  @Test("Custom alert renders a snapshot")
  func rendersSnapshot() throws {
    let view = CustomAlertView(
      title: "회원가입이 완료되었습니다!",
      message: "프로필을 작성할까요?",
      cancelTitle: "나중에 할래요",
      confirmTitle: "지금 할래요",
      onCancel: {},
      onConfirm: {}
    )
    .frame(width: 390, height: 844)

    let renderer = ImageRenderer(content: view)
    renderer.scale = 1

    let snapshotURL = URL(fileURLWithPath: NSTemporaryDirectory())
      .appending(path: "custom-alert-view.png")

    guard let cgImage = renderer.cgImage else {
      Issue.record("Failed to render custom alert snapshot")
      return
    }

    guard let destination = CGImageDestinationCreateWithURL(
      snapshotURL as CFURL,
      UTType.png.identifier as CFString,
      1,
      nil
    ) else {
      Issue.record("Failed to create snapshot destination")
      return
    }

    CGImageDestinationAddImage(destination, cgImage, nil)
    #expect(CGImageDestinationFinalize(destination))
    #expect(FileManager.default.fileExists(atPath: snapshotURL.path()))
    print("CustomAlertView snapshot: \(snapshotURL.path())")
  }
}
