import Foundation
import Observation
import Photos
import UIKit

@MainActor
@Observable
final class PlaygroundViewModel {
  var state = PlaygroundState()

  private let filterID: String
  private let service: any FilterDetailServicing
  private let mediaApplyUseCase: any FilterMediaApplying

  init(
    filterID: String,
    service: (any FilterDetailServicing)? = nil,
    mediaApplyUseCase: (any FilterMediaApplying)? = nil
  ) {
    self.filterID = filterID
    self.service = service ?? LiveFilterDetailService()
    self.mediaApplyUseCase = mediaApplyUseCase ?? LiveFilterMediaApplyUseCase()
  }

  func send(_ action: PlaygroundAction) async {
    switch action {
    case .task, .retry:
      await load()
    case .tapApply:
      guard state.detail != nil else { return }
      state.applyPhase = .picking
    case let .mediaSelected(inputs):
      await apply(inputs: inputs)
    case .saveCurrent:
      await saveCurrent()
    case .saveAll:
      await saveAll()
    case let .previewIndexChanged(index):
      if case let .readyToSave(outputs, _) = state.applyPhase {
        state.applyPhase = .readyToSave(outputs: outputs, currentIndex: index)
      }
    case .dismissApplySheet:
      state.applyPhase = .idle
    }
  }

  private func load() async {
    state.phase = .loading
    state.message = nil
    do {
      state.detail = try await service.loadFilterDetail(filterID: filterID)
      state.phase = .loaded
    } catch {
      let message = (error as? LocalizedError)?.errorDescription ?? "필터 정보를 불러올 수 없습니다."
      state.message = message
      state.phase = .failed(message)
    }
  }

  private func apply(inputs: [FilterMediaInput]) async {
    guard let detail = state.detail else { return }
    var outputs: [FilterMediaOutput] = []

    for (index, input) in inputs.enumerated() {
      state.applyPhase = .rendering(progress: index, total: inputs.count)
      do {
        outputs.append(try await mediaApplyUseCase.apply(input: input, filterValues: detail.filterValues))
      } catch {
        state.applyPhase = .failed("필터 적용에 실패했습니다.")
        return
      }
    }

    state.applyPhase = .readyToSave(outputs: outputs, currentIndex: 0)
  }

  private func saveCurrent() async {
    guard case let .readyToSave(outputs, currentIndex) = state.applyPhase,
          outputs.indices.contains(currentIndex) else { return }
    await persist([outputs[currentIndex]])
  }

  private func saveAll() async {
    guard case let .readyToSave(outputs, _) = state.applyPhase else { return }
    await persist(outputs)
  }

  private func persist(_ outputs: [FilterMediaOutput]) async {
    let total = outputs.count
    for (index, output) in outputs.enumerated() {
      state.applyPhase = .saving(progress: index, total: total)
      do {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
          PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            switch output {
            case let .image(_, cgImage, _):
              request.addResource(
                with: .photo,
                data: UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.95) ?? Data(),
                options: nil
              )
            case let .video(_, fileURL, _):
              request.addResource(with: .video, fileURL: fileURL, options: nil)
            }
          }) { _, error in
            if let error {
              continuation.resume(throwing: error)
            } else {
              continuation.resume()
            }
          }
        }
      } catch {
        state.applyPhase = .failed("앨범 저장에 실패했습니다.")
        return
      }
    }
    state.applyPhase = .saved
  }
}
