import Foundation
import SwiftData

@MainActor
protocol LocalSessionDataResetting: Sendable {
  func resetLocalSessionData() throws
}

@MainActor
struct SwiftDataLocalSessionDataResetter: LocalSessionDataResetting {
  private let container: ModelContainer

  init(container: ModelContainer) {
    self.container = container
  }

  func resetLocalSessionData() throws {
    let context = container.mainContext
    try context.delete(model: ChatMessageRecord.self)
    try context.delete(model: ChatRoomRecord.self)
    try context.save()
  }
}
