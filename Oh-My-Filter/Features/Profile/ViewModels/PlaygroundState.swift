import Foundation

nonisolated struct PlaygroundState: Sendable {
  var phase: PlaygroundPhase = .idle
  var applyPhase: ApplyPhotoPhase = .idle
  var detail: FilterDetail?
  var message: String?

  var filterTitle: String {
    detail?.title ?? "Playground"
  }
}

nonisolated enum PlaygroundPhase: Equatable, Sendable {
  case idle
  case loading
  case loaded
  case failed(String)
}

nonisolated enum PlaygroundAction: Sendable {
  case task
  case retry
  case tapApply
  case mediaSelected([FilterMediaInput])
  case saveCurrent
  case saveAll
  case previewIndexChanged(Int)
  case dismissApplySheet
}
