import Foundation
import Observation
import OSLog

@MainActor
@Observable
final class FilterDetailViewModel {
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "FilterDetailViewModel"
  )

  var state = FilterDetailState()

  private let filterID: String
  private let useCase: any FilterDetailUseCase
  private let renderer: any ImageFilterRendering

  init(
    filterID: String,
    useCase: any FilterDetailUseCase,
    renderer: any ImageFilterRendering
  ) {
    self.filterID = filterID
    self.useCase = useCase
    self.renderer = renderer
  }

  convenience init(
    filterID: String,
    service: any FilterDetailServicing,
    renderer: any ImageFilterRendering = CoreImageFilterRenderer()
  ) {
    self.init(
      filterID: filterID,
      useCase: LiveFilterDetailUseCase(service: service),
      renderer: renderer
    )
  }

  convenience init(filterID: String) {
    self.init(
      filterID: filterID,
      useCase: LiveFilterDetailUseCase(),
      renderer: CoreImageFilterRenderer()
    )
  }

  func send(_ action: FilterDetailAction) async {
    switch action {
    case .task, .retry:
      await load()
    case .tapDownload:
      showDownloadAlert()
    case .dismissAlert, .confirmAlert:
      state.alert = nil
    }
  }

  private func load() async {
    let previous = state.detail
    state.phase = .loading(previous: previous)

    do {
      let detail = try await useCase.loadFilterDetail(filterID: filterID)
      state.phase = .loaded(detail, .rendering)
      await renderPreview(for: detail)
    } catch is CancellationError {
      state.phase = previous.map { .loaded($0, .fallback(originalImageURL: $0.originalImageURL, filteredImageURL: $0.fallbackFilteredImageURL)) } ?? .idle
    } catch {
      state.phase = .failed(message: Self.fallbackMessage(for: error), previous: previous)
      Self.logger.error("❌ [FilterDetailViewModel] load failed \(String(describing: error), privacy: .public)")
    }
  }

  private func renderPreview(for detail: FilterDetail) async {
    guard let originalImageURL = detail.originalImageURL else {
      state.phase = .loaded(detail, .fallback(originalImageURL: nil, filteredImageURL: detail.fallbackFilteredImageURL))
      return
    }

    do {
      let renderedImages = try await renderer.render(
        originalImageURL: originalImageURL,
        filterValues: detail.filterValues
      )
      state.phase = .loaded(detail, .rendered(renderedImages))
    } catch is CancellationError {
      state.phase = .loaded(detail, .fallback(originalImageURL: detail.originalImageURL, filteredImageURL: detail.fallbackFilteredImageURL))
    } catch {
      state.phase = .loaded(detail, .fallback(originalImageURL: detail.originalImageURL, filteredImageURL: detail.fallbackFilteredImageURL))
      Self.logger.error("❌ [FilterDetailViewModel] render failed \(String(describing: error), privacy: .public)")
    }
  }

  private func showDownloadAlert() {
    state.alert = FilterDetailAlert(
      title: "필터 결제",
      message: "결제 기능은 준비 중입니다.",
      cancelTitle: "취소",
      confirmTitle: "확인"
    )
  }

  private static func fallbackMessage(for error: Error) -> String {
    if let serviceError = error as? FilterDetailServiceError,
       let message = serviceError.errorDescription {
      return message
    }

    return FilterDetailServiceError.serverError.errorDescription ?? "잠시 후 다시 시도해 주세요."
  }
}
