import Foundation

nonisolated enum MainAction: Equatable, Sendable {
  case task
  case retryTodayFilter
  case retryMainBanners
  case retryHotTrendFilters
  case retryTodayAuthor
}
