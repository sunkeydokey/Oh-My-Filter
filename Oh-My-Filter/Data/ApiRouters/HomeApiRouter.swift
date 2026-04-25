import Foundation

nonisolated enum HomeApiRouter: ApiRouter {
  case todayFilter
  case mainBanners
  case hotTrendFilters

  var url: String {
    switch self {
    case .todayFilter:
      EndPoint.Filters.today
    case .mainBanners:
      EndPoint.Banners.main
    case .hotTrendFilters:
      EndPoint.Filters.hotTrend
    }
  }

  var method: HttpMethod {
    .get
  }

  var contentType: ContentType {
    .json
  }

  var requiresAuthorizationHeader: Bool {
    true
  }
}
