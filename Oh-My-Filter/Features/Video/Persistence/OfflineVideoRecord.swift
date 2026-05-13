import Foundation
import SwiftData

@Model
final class OfflineVideoRecord {
  @Attribute(.unique) var videoId: String
  var localPath: String
  var title: String
  var savedAt: Date

  init(videoId: String, localPath: String, title: String, savedAt: Date = Date()) {
    self.videoId = videoId
    self.localPath = localPath
    self.title = title
    self.savedAt = savedAt
  }

  var localURL: URL {
    URL.documentsDirectory.appending(path: localPath)
  }
}
