import Foundation

enum VideoDownloadEvent: Sendable {
  case progress(Double)         // 0.0 ~ 1.0
  case completed(localURL: URL)
  case failed(any Error & Sendable)
  case cancelled
}

protocol VideoDownloadManaging: AnyObject, Sendable {
  func startDownload(videoId: String, hlsURL: URL, title: String) async
  func cancelDownload(videoId: String)
  func progressStream(for videoId: String) -> AsyncStream<VideoDownloadEvent>
}
