import Foundation

nonisolated enum FilterMakeAction: Equatable, Sendable {
  case nameChanged(String)
  case categorySelected(FilterMakeCategory)
  case introductionChanged(String)
  case priceChanged(String)
  case representativeImageChanged(Data?)
  case representativeImageInfoChanged(FilterMakeSelectedImageInfo)
  case filterParameterValuesChanged([FilterEditParameter: Double])
  case submitTapped
}
