import Foundation

nonisolated enum FilterMakeCategory: String, CaseIterable, Hashable, Sendable {
  case food = "푸드"
  case portrait = "인물"
  case landscape = "풍경"
  case night = "야경"
  case star = "별"
}
