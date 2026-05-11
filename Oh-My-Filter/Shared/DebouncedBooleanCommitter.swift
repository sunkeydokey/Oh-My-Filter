import Foundation

@MainActor
final class DebouncedBooleanCommitter {
  private let duration: Duration
  private var task: Task<Void, Never>?

  init(duration: Duration = .milliseconds(300)) {
    self.duration = duration
  }

  deinit {
    task?.cancel()
  }

  func schedule(
    status: Bool,
    operation: @escaping @Sendable (Bool) async throws -> Bool,
    completion: @escaping @MainActor @Sendable (Result<Bool, Error>, Bool) -> Void
  ) {
    task?.cancel()
    task = Task { [duration] in
      do {
        try await Task.sleep(for: duration)
        let confirmedStatus = try await operation(status)
        guard Task.isCancelled == false else { return }
        completion(.success(confirmedStatus), status)
      } catch is CancellationError {
      } catch {
        guard Task.isCancelled == false else { return }
        completion(.failure(error), status)
      }
    }
  }

  func cancel() {
    task?.cancel()
    task = nil
  }
}
