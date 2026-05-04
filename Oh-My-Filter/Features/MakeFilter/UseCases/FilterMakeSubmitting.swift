import Foundation

nonisolated protocol FilterMakeSubmitting: Sendable {
  func submit(draft: FilterMakeDraft, mode: FilterMakeMode) async throws -> FilterDetail
}
