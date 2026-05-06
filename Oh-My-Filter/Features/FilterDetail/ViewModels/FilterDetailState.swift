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
