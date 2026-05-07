import CoreGraphics
import Foundation

nonisolated struct FilterDetailState: Sendable {
  var phase: FilterDetailPhase = .idle
  var alert: FilterDetailAlert?
  var paymentRequest: PortonePaymentRequest?
  var isPaymentProcessing = false
  var expandedReplyCommentIDs: Set<String> = []
  var commentText = ""
  var replyingToCommentID: String?
  var currentUserID: String?
  var route: FilterDetailRoute?
  var applyPhotoPhase: ApplyPhotoPhase = .idle

  var detail: FilterDetail? {
    switch phase {
    case .idle, .loading(previous: nil), .failed(_, previous: nil):
      nil
    case let .loading(previous?), let .loaded(previous, _), let .failed(_, previous?):
      previous
    }
  }

  var isMine: Bool {
    guard let currentUserID, currentUserID.isEmpty == false else { return false }
    return detail?.creator.id == currentUserID
  }

  var isOwned: Bool {
    isMine || (detail?.isDownloaded ?? false)
  }
}

nonisolated enum FilterDetailRoute: Equatable, Sendable {
  case update(FilterMakeDraft)
}

nonisolated enum FilterDetailPhase: Sendable {
  case idle
  case loading(previous: FilterDetail?)
  case loaded(FilterDetail, FilterComparisonPreviewState)
  case failed(message: String, previous: FilterDetail?)
}

nonisolated struct FilterDetailAlert: Equatable, Sendable {
  let title: String
  let message: String
  let cancelTitle: String
  let confirmTitle: String
}

nonisolated enum ApplyPhotoPhase: Sendable {
  case idle
  case picking
  case rendering(progress: Int, total: Int)
  case readyToSave(images: [CGImage], currentIndex: Int)
  case saving(progress: Int, total: Int)
  case saved
  case failed(String)
}

extension ApplyPhotoPhase: Equatable {
  static func == (lhs: ApplyPhotoPhase, rhs: ApplyPhotoPhase) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle), (.picking, .picking), (.saved, .saved):
      true
    case let (.rendering(lp, lt), .rendering(rp, rt)):
      lp == rp && lt == rt
    case let (.saving(lp, lt), .saving(rp, rt)):
      lp == rp && lt == rt
    case let (.readyToSave(li, lIdx), .readyToSave(ri, rIdx)):
      lIdx == rIdx && li.count == ri.count && zip(li, ri).allSatisfy { $0 === $1 }
    case let (.failed(l), .failed(r)):
      l == r
    default:
      false
    }
  }
}
