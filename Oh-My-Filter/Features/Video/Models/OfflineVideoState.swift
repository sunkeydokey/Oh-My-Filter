import Foundation

enum OfflineVideoState: Equatable {
  case none
  case downloading(progress: Double)
  case saved
}
