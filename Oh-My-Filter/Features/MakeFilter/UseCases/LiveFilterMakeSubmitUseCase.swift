import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated struct LiveFilterMakeSubmitUseCase: FilterMakeSubmitting {
  private let service: any FilterMakeServicing
  private let renderer: any ImageFilterRendering
  private let imageUploadUseCase: any ImageUploadUseCase

  init(
    service: any FilterMakeServicing,
    renderer: any ImageFilterRendering = CoreImageFilterRenderer(),
    imageUploadUseCase: any ImageUploadUseCase = LiveImageUploadUseCase()
  ) {
    self.service = service
    self.renderer = renderer
    self.imageUploadUseCase = imageUploadUseCase
  }

  @MainActor
  init() {
    self.init(service: LiveFilterMakeService())
  }

  func submit(draft: FilterMakeDraft, mode: FilterMakeMode) async throws -> FilterDetail {
    let imageData = try requiredRepresentativeImageData(from: draft)
    let renderedImages = try await renderer.render(
      originalImageData: imageData,
      filterValues: draft.filterValues
    )
    let filteredImageData = try jpegData(from: renderedImages.filtered)
    let uploadedFiles = try await uploadFiles(originalImageData: imageData, filteredImageData: filteredImageData)
    let request = FilterMakeRequest(draft: draft, files: uploadedFiles)

    switch mode {
    case .create:
      return try await service.createFilter(request: request)
    case let .update(filterID):
      return try await service.updateFilter(filterID: filterID, request: request)
    }
  }

  private func requiredRepresentativeImageData(from draft: FilterMakeDraft) throws -> Data {
    guard let imageData = draft.representativeImageData else {
      throw FilterMakeServiceError.invalidRequest("대표 사진을 선택해주세요.")
    }

    return imageData
  }

  private func uploadFiles(
    originalImageData: Data,
    filteredImageData: Data
  ) async throws -> [String] {
    let selections = [
      PhotoPickerUploadSelection(data: originalImageData, fileName: "filter-original.jpg"),
      PhotoPickerUploadSelection(data: filteredImageData, fileName: "filter-applied.jpg"),
    ]
    let fileParts = try await imageUploadUseCase.multipartFiles(from: selections, preset: .filter)
    return try await service.uploadFiles(fileParts)
  }

  private func jpegData(from image: CGImage) throws -> Data {
    let data = NSMutableData()
    guard
      let destination = CGImageDestinationCreateWithData(
        data,
        UTType.jpeg.identifier as CFString,
        1,
        nil
      )
    else {
      throw FilterMakeServiceError.invalidResponse
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
      throw FilterMakeServiceError.invalidResponse
    }

    return data as Data
  }
}
