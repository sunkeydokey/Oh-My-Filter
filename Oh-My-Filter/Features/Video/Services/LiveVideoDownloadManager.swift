import AVFoundation
import Foundation
import OSLog
import SwiftUI

@MainActor
final class LiveVideoDownloadManager: NSObject, VideoDownloadManaging, @unchecked Sendable {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "LiveVideoDownloadManager"
  )

  private let offlineStore: any OfflineVideoStoring
  private lazy var downloadSession: AVAssetDownloadURLSession = {
    let config = URLSessionConfiguration.background(
      withIdentifier: "com.oh-my-filter.video-download"
    )
    return AVAssetDownloadURLSession(
      configuration: config,
      assetDownloadDelegate: self,
      delegateQueue: .main
    )
  }()

  // videoId → (task, title, continuation)
  private var activeTasks: [String: (task: AVAssetDownloadTask, title: String, continuation: AsyncStream<VideoDownloadEvent>.Continuation)] = [:]
  private var streamCache: [String: AsyncStream<VideoDownloadEvent>] = [:]

  init(offlineStore: any OfflineVideoStoring) {
    self.offlineStore = offlineStore
  }

  func startDownload(videoId: String, hlsURL: URL, title: String) async {
    guard activeTasks[videoId] == nil else { return }

    let asset = AVURLAsset(url: hlsURL)
    guard let task = downloadSession.makeAssetDownloadTask(
      asset: asset,
      assetTitle: title,
      assetArtworkData: nil,
      options: nil
    ) else {
      Self.logger.error("❌ [LiveVideoDownloadManager] makeAssetDownloadTask failed for videoId=\(videoId, privacy: .public)")
      return
    }

    let stream = AsyncStream<VideoDownloadEvent> { continuation in
      self.activeTasks[videoId] = (task: task, title: title, continuation: continuation)
      continuation.onTermination = { [weak self] _ in
        Task { @MainActor [weak self] in
          self?.activeTasks.removeValue(forKey: videoId)
        }
      }
    }
    streamCache[videoId] = stream

    task.taskDescription = videoId
    task.resume()
    Self.logger.info("ℹ️ [LiveVideoDownloadManager] download started videoId=\(videoId, privacy: .public)")
  }

  func cancelDownload(videoId: String) {
    guard let entry = activeTasks[videoId] else { return }
    entry.task.cancel()
    entry.continuation.yield(.cancelled)
    entry.continuation.finish()
    activeTasks.removeValue(forKey: videoId)
    streamCache.removeValue(forKey: videoId)
    Self.logger.info("ℹ️ [LiveVideoDownloadManager] download cancelled videoId=\(videoId, privacy: .public)")
  }

  func progressStream(for videoId: String) -> AsyncStream<VideoDownloadEvent> {
    streamCache[videoId] ?? AsyncStream { $0.finish() }
  }
}

extension LiveVideoDownloadManager: AVAssetDownloadDelegate {
  nonisolated func urlSession(
    _ session: URLSession,
    assetDownloadTask: AVAssetDownloadTask,
    didLoad timeRange: CMTimeRange,
    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
    timeRangeExpectedToLoad: CMTimeRange
  ) {
    guard let videoId = assetDownloadTask.taskDescription else { return }
    let total = timeRangeExpectedToLoad.duration.seconds
    guard total > 0 else { return }
    let loaded = loadedTimeRanges
      .map { $0.timeRangeValue.duration.seconds }
      .reduce(0, +)
    let progress = min(loaded / total, 1.0)
    Task { @MainActor [weak self] in
      self?.activeTasks[videoId]?.continuation.yield(.progress(progress))
    }
  }

  nonisolated func urlSession(
    _ session: URLSession,
    assetDownloadTask: AVAssetDownloadTask,
    didFinishDownloadingTo location: URL
  ) {
    guard let videoId = assetDownloadTask.taskDescription else { return }

    Task { @MainActor [weak self] in
      guard let self else { return }
      guard let title = activeTasks[videoId]?.title else { return }

      let fileName = "\(videoId).movpkg"
      let destURL = URL.documentsDirectory.appending(path: fileName)

      do {
        if FileManager.default.fileExists(atPath: destURL.path()) {
          try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.moveItem(at: location, to: destURL)
      } catch {
        Self.logger.error("❌ [LiveVideoDownloadManager] file move failed: \(String(describing: error), privacy: .public)")
        activeTasks[videoId]?.continuation.yield(.failed(error as any Error & Sendable))
        activeTasks[videoId]?.continuation.finish()
        activeTasks.removeValue(forKey: videoId)
        streamCache.removeValue(forKey: videoId)
        return
      }

      let record = OfflineVideoRecord(videoId: videoId, localPath: fileName, title: title)
      do {
        try await offlineStore.save(record)
        activeTasks[videoId]?.continuation.yield(.completed(localURL: destURL))
        activeTasks[videoId]?.continuation.finish()
        Self.logger.info("ℹ️ [LiveVideoDownloadManager] download completed videoId=\(videoId, privacy: .public)")
      } catch {
        Self.logger.error("❌ [LiveVideoDownloadManager] store save failed: \(String(describing: error), privacy: .public)")
        activeTasks[videoId]?.continuation.yield(.failed(error as any Error & Sendable))
        activeTasks[videoId]?.continuation.finish()
      }
      activeTasks.removeValue(forKey: videoId)
      streamCache.removeValue(forKey: videoId)
    }
  }

  nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error, let videoId = task.taskDescription else { return }
    let nsError = error as NSError
    guard nsError.code != NSURLErrorCancelled else { return }
    Self.logger.error("❌ [LiveVideoDownloadManager] task error videoId=\(videoId, privacy: .public) error=\(String(describing: error), privacy: .public)")
    Task { @MainActor [weak self] in
      self?.activeTasks[videoId]?.continuation.yield(.failed(error as any Error & Sendable))
      self?.activeTasks[videoId]?.continuation.finish()
      self?.activeTasks.removeValue(forKey: videoId)
      self?.streamCache.removeValue(forKey: videoId)
    }
  }
}

private struct VideoDownloadManagerKey: EnvironmentKey {
  static let defaultValue: (any VideoDownloadManaging)? = nil
}

extension EnvironmentValues {
  var videoDownloadManager: (any VideoDownloadManaging)? {
    get { self[VideoDownloadManagerKey.self] }
    set { self[VideoDownloadManagerKey.self] = newValue }
  }
}
