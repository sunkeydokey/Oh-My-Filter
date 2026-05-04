import Foundation

nonisolated struct FilterMakeRequest: Encodable, Equatable, Sendable {
  let category: String
  let title: String
  let description: String
  let files: [String]
  let photoMetadata: FilterMakePhotoMetadataRequest
  let filterValues: FilterMakeValuesRequest
  let price: Int

  init(
    draft: FilterMakeDraft,
    files: [String]
  ) {
    category = draft.category.rawValue
    title = draft.name
    description = draft.introduction
    self.files = files
    photoMetadata = FilterMakePhotoMetadataRequest(metadata: draft.photoMetadata)
    filterValues = FilterMakeValuesRequest(values: draft.filterValues)
    price = draft.price
  }

  private enum CodingKeys: String, CodingKey {
    case category
    case title
    case description
    case files
    case photoMetadata = "photo_metadata"
    case filterValues = "filter_values"
    case price
  }
}

nonisolated struct FilterMakePhotoMetadataRequest: Encodable, Equatable, Sendable {
  let camera: String?
  let lensInfo: String?
  let focalLength: Int?
  let aperture: Double?
  let shutterSpeed: String?
  let iso: Int?
  let pixelWidth: Int?
  let pixelHeight: Int?
  let fileSize: Int?
  let format: String?
  let dateTimeOriginal: String?
  let latitude: Double?
  let longitude: Double?

  init(metadata: FilterDetailMetadata) {
    camera = metadata.camera
    lensInfo = metadata.lens
    
    if let focalLengthStr = metadata.focalLength {
      let cleaned = focalLengthStr.replacingOccurrences(of: " mm", with: "")
      focalLength = Double(cleaned).map { Int($0) }
    } else {
      focalLength = nil
    }
    
    if let apertureStr = metadata.aperture {
      let cleaned = apertureStr.replacingOccurrences(of: "f ", with: "")
      aperture = Double(cleaned)
    } else {
      aperture = nil
    }
    
    shutterSpeed = metadata.shutterSpeed
    
    if let isoStr = metadata.iso {
      iso = Int(isoStr)
    } else {
      iso = nil
    }
    
    pixelWidth = nil
    pixelHeight = nil
    fileSize = nil
    format = nil
    dateTimeOriginal = nil
    latitude = nil
    longitude = nil
  }

  private enum CodingKeys: String, CodingKey {
    case camera
    case lensInfo = "lens_info"
    case focalLength = "focal_length"
    case aperture
    case shutterSpeed = "shutter_speed"
    case iso
    case pixelWidth = "pixel_width"
    case pixelHeight = "pixel_height"
    case fileSize = "file_size"
    case format
    case dateTimeOriginal = "date_time_original"
    case latitude
    case longitude
  }
}

nonisolated struct FilterMakeValuesRequest: Encodable, Equatable, Sendable {
  let brightness: Double
  let contrast: Double
  let saturation: Double
  let exposure: Double
  let sharpness: Double
  let blur: Double
  let vignette: Double
  let noiseReduction: Double
  let highlights: Double
  let shadows: Double
  let temperature: Double
  let blackPoint: Double

  init(values: FilterValues) {
    brightness = values.brightness
    contrast = values.contrast
    saturation = values.saturation
    exposure = values.exposure
    sharpness = values.sharpen
    blur = values.blur
    vignette = values.vignette
    noiseReduction = values.noiseReduction
    highlights = values.highlights
    shadows = values.shadows
    temperature = values.temperature
    blackPoint = values.blackPoint
  }

  private enum CodingKeys: String, CodingKey {
    case brightness
    case contrast
    case saturation
    case exposure
    case sharpness
    case blur
    case vignette
    case noiseReduction = "noise_reduction"
    case highlights
    case shadows
    case temperature
    case blackPoint = "black_point"
  }
}
