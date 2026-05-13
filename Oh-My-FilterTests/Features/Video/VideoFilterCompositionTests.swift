import AVFoundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct VideoFilterCompositionTests {
  @Test("make throws when asset is not playable")
  func makeThrowsWhenAssetIsNotPlayable() async throws {
    // AVMutableComposition with no tracks → isPlayable == false
    let item = AVPlayerItem(asset: AVMutableComposition())

    await #expect(throws: VideoFilterCompositionError.notPlayable) {
      _ = try await VideoFilterComposition.make(for: item, filterValues: .neutral)
    }
  }
}
