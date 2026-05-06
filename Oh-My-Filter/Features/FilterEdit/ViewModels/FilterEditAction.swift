import Foundation

nonisolated enum FilterEditAction: Equatable, Sendable {
  case parameterSelected(FilterEditParameter)
  case valueEditingStarted
  case valueChanged(Double)
  case valueEditingEnded
  case undo
  case redo
  case reset
}
