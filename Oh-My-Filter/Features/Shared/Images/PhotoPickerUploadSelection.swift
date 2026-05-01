import Foundation

nonisolated struct PhotoPickerUploadSelection: Equatable, Identifiable, Sendable {
  let id: UUID
  let data: Data
  let fileName: String

  init(
    id: UUID = UUID(),
    data: Data,
    fileName: String
  ) {
    self.id = id
    self.data = data
    self.fileName = fileName
  }
}
