import AVFoundation
import CoreImage

nonisolated enum VideoFilterCompositionError: Error, Equatable, Sendable {
  case notPlayable
  case notComposable
  case noVideoTrack
}

enum VideoFilterComposition {
  static func make(for playerItem: AVPlayerItem, filterValues: FilterValues) async throws -> AVVideoComposition {
    try await make(for: playerItem.asset, filterValues: filterValues)
  }

  static func make(for asset: AVAsset, filterValues: FilterValues) async throws -> AVVideoComposition {
    let capturedValues = filterValues
    let isPlayable = try await asset.load(.isPlayable)
    guard isPlayable else { throw VideoFilterCompositionError.notPlayable }
    let isComposable = try await asset.load(.isComposable)
    guard isComposable else { throw VideoFilterCompositionError.notComposable }
    let tracks = try await asset.load(.tracks)
    guard tracks.contains(where: { $0.mediaType == .video }) else {
      throw VideoFilterCompositionError.noVideoTrack
    }

    return try await AVVideoComposition(applyingFiltersTo: asset) { params in
      let output = applyFilterValues(capturedValues, to: params.sourceImage)
      return AVCIImageFilteringResult(resultImage: output)
    }
  }
}

nonisolated func applyFilterValues(_ filterValues: FilterValues, to image: CIImage) -> CIImage {
  let neutralTemperature = FilterValues.neutral.temperature
  var output = image

  output = output.applyingFilter(
    "CIColorControls",
    parameters: [
      kCIInputBrightnessKey: filterValues.brightness,
      kCIInputContrastKey: filterValues.contrast,
      kCIInputSaturationKey: filterValues.saturation
    ]
  )

  if filterValues.exposure != 0 {
    output = output.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: filterValues.exposure])
  }

  if filterValues.temperature != neutralTemperature {
    output = output.applyingFilter(
      "CITemperatureAndTint",
      parameters: [
        "inputNeutral": CIVector(x: filterValues.temperature, y: 0),
        "inputTargetNeutral": CIVector(x: neutralTemperature, y: 0)
      ]
    )
  }

  if filterValues.highlights != 0 || filterValues.shadows != 0 {
    output = output.applyingFilter(
      "CIHighlightShadowAdjust",
      parameters: [
        "inputHighlightAmount": 1 + filterValues.highlights,
        "inputShadowAmount": filterValues.shadows
      ]
    )
  }

  if filterValues.noiseReduction > 0 {
    output = output.applyingFilter(
      "CINoiseReduction",
      parameters: [
        "inputNoiseLevel": filterValues.noiseReduction,
        "inputSharpness": max(filterValues.sharpen, 0)
      ]
    )
  }

  if filterValues.sharpen > 0 {
    output = output.applyingFilter("CISharpenLuminance", parameters: [kCIInputSharpnessKey: filterValues.sharpen])
  }

  if filterValues.blur > 0 {
    let extent = image.extent
    output = output
      .clampedToExtent()
      .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: filterValues.blur])
      .cropped(to: extent)
  }

  if filterValues.vignette > 0 {
    let size = image.extent.size
    output = output.applyingFilter(
      "CIVignette",
      parameters: [
        kCIInputIntensityKey: filterValues.vignette,
        kCIInputRadiusKey: max(size.width, size.height) * 0.55
      ]
    )
  }

  if filterValues.blackPoint != 0 {
    let bp = filterValues.blackPoint
    output = output.applyingFilter(
      "CIColorMatrix",
      parameters: [
        "inputRVector": CIVector(x: 1 - bp, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: 1 - bp, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: 1 - bp, w: 0),
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
      ]
    )
  }

  return output
}
