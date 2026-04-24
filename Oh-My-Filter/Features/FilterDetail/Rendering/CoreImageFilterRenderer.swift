import CoreGraphics
import CoreImage
import Foundation

nonisolated struct CoreImageFilterRenderer: ImageFilterRendering {
  private let session: URLSession
  private let context: CIContext

  init(
    session: URLSession = .shared,
    context: CIContext = CIContext()
  ) {
    self.session = session
    self.context = context
  }

  func render(originalImageURL: URL, filterValues: FilterValues) async throws -> RenderedFilterImages {
    var request = URLRequest(url: originalImageURL)
    request.setValue(Server.apiKey(), forHTTPHeaderField: "SeSACKey")
    if let accessToken = KeychainAuthTokenStore.currentAccessToken() {
      request.setValue(accessToken, forHTTPHeaderField: "Authorization")
    }

    let (data, _) = try await session.data(for: request)
    guard let originalImage = CIImage(data: data) else {
      throw ImageFilterRenderingError.invalidImageData
    }

    let filteredImage = apply(filterValues, to: originalImage)
    guard let originalCGImage = context.createCGImage(originalImage, from: originalImage.extent),
          let filteredCGImage = context.createCGImage(filteredImage, from: originalImage.extent) else {
      throw ImageFilterRenderingError.renderFailed
    }

    return RenderedFilterImages(original: originalCGImage, filtered: filteredCGImage)
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

    if values.temperature != 0 || values.tint != 0 {
      output = output.applyingFilter(
        "CITemperatureAndTint",
        parameters: [
          "inputNeutral": CIVector(x: 6500 + values.temperature, y: values.tint),
          "inputTargetNeutral": CIVector(x: 6500, y: 0)
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
