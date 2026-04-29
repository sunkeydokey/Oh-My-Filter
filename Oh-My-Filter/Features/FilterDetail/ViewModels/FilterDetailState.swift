import Foundation

nonisolated struct FilterDetailState: Sendable {
  var phase: FilterDetailPhase = .idle
  var alert: FilterDetailAlert?
  var paymentRequest: PortonePaymentRequest?
  var isPaymentProcessing = false

  var detail: FilterDetail? {
    switch phase {
    case .idle, .loading(previous: nil), .failed(_, previous: nil):
      nil
    case let .loading(previous?), let .loaded(previous, _), let .failed(_, previous?):
      previous
    }
  }
}

nonisolated enum FilterDetailPhase: Sendable {
  case idle
  case loading(previous: FilterDetail?)
  case loaded(FilterDetail, FilterDetailPreviewState)
  case failed(message: String, previous: FilterDetail?)
}

nonisolated enum FilterDetailPreviewState: Sendable {
  case rendering
  case rendered(RenderedFilterImages)
  case fallback(originalImageURL: URL?, filteredImageURL: URL?)
}

nonisolated struct FilterDetailAlert: Equatable, Sendable {
  let title: String
  let message: String
  let cancelTitle: String
  let confirmTitle: String
}
