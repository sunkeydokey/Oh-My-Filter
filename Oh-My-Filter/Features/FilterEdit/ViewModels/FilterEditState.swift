import CoreGraphics
import Foundation

nonisolated struct FilterEditState: Equatable, Sendable {
  var draft: FilterMakeDraft
  var previewImage: CGImage?
  var selectedParameter: FilterEditParameter = .saturation
  var history: [[FilterEditParameter: Double]] = []
  var redoStack: [[FilterEditParameter: Double]] = []

  init(draft: FilterMakeDraft) {
    self.draft = draft
  }

  static func == (lhs: FilterEditState, rhs: FilterEditState) -> Bool {
    lhs.draft == rhs.draft
      && lhs.selectedParameter == rhs.selectedParameter
      && lhs.history == rhs.history
      && lhs.redoStack == rhs.redoStack
      && lhs.previewImage === rhs.previewImage
  }
}
