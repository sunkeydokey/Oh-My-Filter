import Foundation
import Testing
@testable import Oh_My_Filter

@MainActor
struct ReconnectionManagerTests {
  @Test("backoff sequence produces correct delays")
  func backoffSequenceProducesCorrectDelays() async throws {
    var recordedDelays: [Double] = []
    let manager = ReconnectionManager(
      maxAttempts: 6,
      maxDelay: 60,
      sleepAction: { duration in
        let seconds = Double(duration.components.seconds)
        recordedDelays.append(seconds)
      }
    )

    for _ in 0..<6 {
      manager.scheduleNext { }
      try await Task.sleep(for: .milliseconds(10))
    }

    #expect(recordedDelays == [1, 2, 4, 8, 16, 32])
  }

  @Test("cancel prevents pending work from executing")
  func cancelPreventsPendingWork() async throws {
    var executed = false
    let manager = ReconnectionManager(
      sleepAction: { _ in try await Task.sleep(for: .seconds(10)) }
    )

    manager.scheduleNext { executed = true }
    manager.cancel()
    try await Task.sleep(for: .milliseconds(50))

    #expect(executed == false)
  }

  @Test("reset returns attempt counter to zero")
  func resetReturnsAttemptToZero() async throws {
    let manager = ReconnectionManager(sleepAction: { _ in })

    manager.scheduleNext { }
    manager.scheduleNext { }
    manager.scheduleNext { }
    #expect(manager.attempt == 3)

    manager.reset()
    #expect(manager.attempt == 0)
  }

  @Test("hasReachedMaxAttempts is true after maxAttempts calls")
  func hasReachedMaxAttemptsAfterMaxAttemptsCalls() async throws {
    let manager = ReconnectionManager(maxAttempts: 3, sleepAction: { _ in })

    #expect(manager.hasReachedMaxAttempts == false)
    manager.scheduleNext { }
    manager.scheduleNext { }
    manager.scheduleNext { }
    #expect(manager.hasReachedMaxAttempts == true)
  }
}
