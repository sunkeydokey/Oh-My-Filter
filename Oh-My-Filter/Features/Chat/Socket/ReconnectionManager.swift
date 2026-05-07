import Foundation

@MainActor
final class ReconnectionManager {
  private(set) var attempt: Int = 0
  private let maxAttempts: Int
  private let maxDelay: TimeInterval
  private var task: Task<Void, Never>?
  private let sleepAction: (Duration) async throws -> Void

  init(
    maxAttempts: Int = 6,
    maxDelay: TimeInterval = 60,
    sleepAction: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
  ) {
    self.maxAttempts = maxAttempts
    self.maxDelay = maxDelay
    self.sleepAction = sleepAction
  }

  var hasReachedMaxAttempts: Bool {
    attempt >= maxAttempts
  }

  func scheduleNext(_ work: @escaping @MainActor () async -> Void) {
    task?.cancel()
    let delay = min(pow(2.0, Double(attempt)), maxDelay)
    attempt += 1
    task = Task { [weak self] in
      try? await self?.sleepAction(.seconds(delay))
      guard Task.isCancelled == false else { return }
      await work()
    }
  }

  func cancel() {
    task?.cancel()
    task = nil
  }

  func reset() {
    attempt = 0
  }
}
