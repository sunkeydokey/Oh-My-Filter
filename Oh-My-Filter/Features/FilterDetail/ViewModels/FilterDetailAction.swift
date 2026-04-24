import Foundation

nonisolated enum FilterDetailAction: Equatable, Sendable {
  case task
  case retry
  case tapDownload
  case dismissAlert
  case confirmAlert
}
