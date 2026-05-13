import Foundation

nonisolated enum FilterMakeAction: Equatable, Sendable {
  case nameChanged(String)
  case categorySelected(FilterMakeCategory)
  case introductionChanged(String)
  case priceChanged(String)
  case representativeImageChanged(Data?)
  case representativeImageInfoChanged(FilterMakeSelectedImageInfo)
  case comparisonPreviewChanged(FilterComparisonPreviewState?)
  case filterParameterValuesChanged([FilterEditParameter: Double])
  case submitTapped
  case routeHandled
  case animeConvertTapped
  case animeConversionProduced(AnimeConversionResult)
  case animeConversionFailed(String)
  case animeConversionChoiceMade(useConverted: Bool)
  case animeConversionDismissed
}
