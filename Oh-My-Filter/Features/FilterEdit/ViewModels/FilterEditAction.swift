import Foundation

nonisolated enum FilterEditAction: Equatable, Sendable {
  case parameterSelected(FilterEditParameter)
  case valueChanged(Double)
  case undo
  case redo
  case reset
}
