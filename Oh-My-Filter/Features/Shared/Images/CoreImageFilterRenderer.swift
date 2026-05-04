import CoreGraphics
import CoreImage
import Foundation
import ImageIO

nonisolated struct CoreImageFilterRenderer: ImageFilterRendering {
  private let session: URLSession
  private let context: CIContext
  private let tokenRefreshCoordinator: any TokenRefreshCoordinating

  init(
    session: URLSession = .shared,
    context: CIContext = CIContext(),
    tokenRefreshCoordinator: any TokenRefreshCoordinating = AppTokenRefreshCoordinator.shared
  ) {
    self.session = session
    self.context = context
    self.tokenRefreshCoordinator = tokenRefreshCoordinator
  }

  func render(originalImageURL: URL, filterValues: FilterValues) async throws -> RenderedFilterImages {
    var request = URLRequest(url: originalImageURL)
    request.setValue(Server.apiKey(), forHTTPHeaderField: "SeSACKey")
    if let accessToken = try? await tokenRefreshCoordinator.authorizationHeaderValue() {
      request.setValue(accessToken, forHTTPHeaderField: "Authorization")
    }

    let (data, _) = try await session.data(for: request)
    return try render(data: data, filterValues: filterValues)
  }

  func render(originalImageData: Data, filterValues: FilterValues) async throws -> RenderedFilterImages {
    try render(data: originalImageData, filterValues: filterValues)
  }

  private func render(data: Data, filterValues: FilterValues) throws -> RenderedFilterImages {
    guard let originalImage = CIImage(data: data) else {
      throw ImageFilterRenderingError.invalidImageData
    }

    let orientedImage = originalImage.oriented(forExifOrientation: exifOrientation(from: data))
    let filteredImage = apply(filterValues, to: orientedImage)
    guard let originalCGImage = context.createCGImage(orientedImage, from: orientedImage.extent),
          let filteredCGImage = context.createCGImage(filteredImage, from: orientedImage.extent) else {
      throw ImageFilterRenderingError.renderFailed
    }

    return RenderedFilterImages(original: originalCGImage, filtered: filteredCGImage)
  }

  private func exifOrientation(from data: Data) -> Int32 {
    guard
      let source = CGImageSourceCreateWithData(data as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let orientation = properties[kCGImagePropertyOrientation]
    else {
      return 1
    }

    if let value = orientation as? Int32 {
      return value
    }

    if let value = orientation as? Int {
      return Int32(value)
    }

    if let value = orientation as? NSNumber {
      return value.int32Value
    }

    return 1
  }

  private func apply(_ values: FilterValues, to image: CIImage) -> CIImage {
    var output = image

    output = output.applyingFilter(
      "CIColorControls",
      parameters: [
        kCIInputBrightnessKey: values.brightness,
        kCIInputContrastKey: values.contrast,
        kCIInputSaturationKey: values.saturation
      ]
    )

    if values.exposure != 0 {
      output = output.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: values.exposure])
    }

    if values.temperature != FilterValues.neutral.temperature {
      output = output.applyingFilter(
        "CITemperatureAndTint",
        parameters: [
          "inputNeutral": CIVector(x: values.temperature, y: 0),
          "inputTargetNeutral": CIVector(x: FilterValues.neutral.temperature, y: 0)
        ]
      )
    }

    if values.highlights != 0 || values.shadows != 0 {
      output = output.applyingFilter(
        "CIHighlightShadowAdjust",
        parameters: [
          "inputHighlightAmount": 1 + values.highlights,
          "inputShadowAmount": values.shadows
        ]
      )
    }

    if values.noiseReduction > 0 {
      output = output.applyingFilter(
        "CINoiseReduction",
        parameters: [
          "inputNoiseLevel": values.noiseReduction,
          "inputSharpness": max(values.sharpen, 0)
        ]
      )
    }

    if values.sharpen > 0 {
      output = output.applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: values.sharpen])
    }

    if values.blur > 0 {
      output = output
        .clampedToExtent()
        .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: values.blur])
        .cropped(to: image.extent)
    }

    if values.vignette > 0 {
      output = output.applyingFilter(
        "CIVignette",
        parameters: [
          kCIInputIntensityKey: values.vignette,
          kCIInputRadiusKey: max(image.extent.width, image.extent.height) * 0.55
        ]
      )
    }

    if values.blackPoint != 0 {
      output = output.applyingFilter(
        "CIColorMatrix",
        parameters: [
          "inputRVector": CIVector(x: 1 - values.blackPoint, y: 0, z: 0, w: 0),
          "inputGVector": CIVector(x: 0, y: 1 - values.blackPoint, z: 0, w: 0),
          "inputBVector": CIVector(x: 0, y: 0, z: 1 - values.blackPoint, w: 0),
          "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ]
      )
    }

    return output
  }
}
