import Foundation

nonisolated enum ProfileRoute: Hashable, Sendable {
  case profile
  case edit
  case receipts
  case playground(filter: OrderHistoryFilter)
  case communityPostCreate(preloadedImages: [PhotoPickerUploadSelection])
}
