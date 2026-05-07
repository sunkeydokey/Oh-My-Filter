import CoreGraphics
import Foundation
import ImageIO

nonisolated struct LiveFilterMakeImageInfoReader: FilterMakeImageInfoReading {
  private let previewMaxPixelSize: Int

  init(previewMaxPixelSize: Int = 1_600) {
    self.previewMaxPixelSize = previewMaxPixelSize
  }

  func selectedImageInfo(from imageData: Data?) async -> FilterMakeSelectedImageInfo {
    await Task.detached(priority: .userInitiated) {
      selectedImageInfo(from: imageData, overridingMetadata: nil, previewMaxPixelSize: previewMaxPixelSize)
    }.value
  }

  func selectedImageInfo(from imageData: Data?, overridingMetadata: FilterDetailMetadata?) async -> FilterMakeSelectedImageInfo {
    await Task.detached(priority: .userInitiated) {
      selectedImageInfo(from: imageData, overridingMetadata: overridingMetadata, previewMaxPixelSize: previewMaxPixelSize)
    }.value
  }

  private func selectedImageInfo(
    from imageData: Data?,
    overridingMetadata: FilterDetailMetadata?,
    previewMaxPixelSize: Int
  ) -> FilterMakeSelectedImageInfo {
    guard
      let imageData,
      let source = CGImageSourceCreateWithData(imageData as CFData, nil),
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [AnyHashable: Any]
    else {
      return FilterMakeSelectedImageInfo(
        imageData: imageData,
        previewImage: previewImage(from: imageData, maxPixelSize: previewMaxPixelSize),
        metadata: overridingMetadata ?? .empty,
        filterParameterValues: FilterEditParameter.defaultValues
      )
    }

    return FilterMakeSelectedImageInfo(
      imageData: imageData,
      previewImage: thumbnail(from: source, maxPixelSize: previewMaxPixelSize),
      metadata: overridingMetadata ?? metadata(from: properties),
      filterParameterValues: filterParameterValues(from: properties)
    )
  }

  private func previewImage(from imageData: Data?, maxPixelSize: Int) -> CGImage? {
    guard let imageData,
          let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
      return nil
    }
    return thumbnail(from: source, maxPixelSize: maxPixelSize)
  }

  private func thumbnail(from source: CGImageSource, maxPixelSize: Int) -> CGImage? {
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
    ]

    return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
  }

  func metadata(from properties: [AnyHashable: Any]) -> FilterDetailMetadata {
    let tiff = dictionaryValue(for: kCGImagePropertyTIFFDictionary, in: properties)
    let exif = dictionaryValue(for: kCGImagePropertyExifDictionary, in: properties)

    return FilterDetailMetadata(
      camera: camera(from: tiff),
      lens: stringValue(for: kCGImagePropertyExifLensModel, in: exif),
      focalLength: focalLength(from: exif),
      aperture: aperture(from: exif),
      shutterSpeed: shutterSpeed(from: exif),
      iso: iso(from: exif)
    )
  }

  private func camera(from tiff: [AnyHashable: Any]?) -> String? {
    let make = stringValue(for: kCGImagePropertyTIFFMake, in: tiff)
    let model = stringValue(for: kCGImagePropertyTIFFModel, in: tiff)

    switch (make, model) {
    case let (make?, model?) where model.localizedStandardContains(make):
      return model
    case let (make?, model?):
      return "\(make) \(model)"
    case let (make?, nil):
      return make
    case let (nil, model?):
      return model
    default:
      return nil
    }
  }

  private func focalLength(from exif: [AnyHashable: Any]?) -> String? {
    guard let value = doubleValue(for: kCGImagePropertyExifFocalLength, in: exif) else {
      return nil
    }
    return "\(value.formatted(.number.precision(.fractionLength(0 ... 1)))) mm"
  }

  private func aperture(from exif: [AnyHashable: Any]?) -> String? {
    guard let value = doubleValue(for: kCGImagePropertyExifFNumber, in: exif) else {
      return nil
    }
    return "f \(value.formatted(.number.precision(.fractionLength(0 ... 1))))"
  }

  private func shutterSpeed(from exif: [AnyHashable: Any]?) -> String? {
    guard let value = doubleValue(for: kCGImagePropertyExifExposureTime, in: exif), value > 0 else {
      return nil
    }

    if value < 1 {
      let denominator = (1 / value).rounded()
      return "1/\(denominator.formatted(.number.precision(.fractionLength(0))))"
    }

    return "\(value.formatted(.number.precision(.fractionLength(0 ... 2))))s"
  }

  private func iso(from exif: [AnyHashable: Any]?) -> String? {
    guard let value = value(for: kCGImagePropertyExifISOSpeedRatings, in: exif) else {
      return nil
    }

    if let values = value as? [Any], let first = values.first {
      return numericText(from: first)
    }

    return numericText(from: value)
  }

  private func filterParameterValues(from properties: [AnyHashable: Any]) -> [FilterEditParameter: Double] {
    var values = FilterEditParameter.defaultValues
    let dictionaries = candidateFilterValueDictionaries(in: properties)
    guard dictionaries.isEmpty == false else { return values }

    for parameter in FilterEditParameter.allCases {
      guard let value = dictionaries.lazy.compactMap({ filterValue(for: parameter, in: $0) }).first else {
        continue
      }
      values[parameter] = parameter.clamped(value)
    }

    return values
  }

  private func candidateFilterValueDictionaries(in value: Any) -> [[String: Any]] {
    var dictionaries: [[String: Any]] = []
    collectFilterValueDictionaries(from: value, into: &dictionaries)
    return dictionaries
  }

  private func collectFilterValueDictionaries(from value: Any, into dictionaries: inout [[String: Any]]) {
    if let dictionary = value as? [String: Any] {
      appendFilterValueDictionary(dictionary, into: &dictionaries)
      dictionary.values.forEach { collectFilterValueDictionaries(from: $0, into: &dictionaries) }
      return
    }

    if let dictionary = value as? [AnyHashable: Any] {
      var stringDictionary: [String: Any] = [:]
      dictionary.forEach { key, value in
        stringDictionary[String(describing: key)] = value
      }
      appendFilterValueDictionary(stringDictionary, into: &dictionaries)
      stringDictionary.values.forEach { collectFilterValueDictionaries(from: $0, into: &dictionaries) }
      return
    }

    if let array = value as? [Any] {
      array.forEach { collectFilterValueDictionaries(from: $0, into: &dictionaries) }
      return
    }

    if let string = value as? String,
       let data = string.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data) {
      collectFilterValueDictionaries(from: json, into: &dictionaries)
    }
  }

  private func appendFilterValueDictionary(_ dictionary: [String: Any], into dictionaries: inout [[String: Any]]) {
    if let nested = nestedDictionary(named: "filter_values", in: dictionary) {
      dictionaries.append(nested)
    }
    if let nested = nestedDictionary(named: "filterValues", in: dictionary) {
      dictionaries.append(nested)
    }
    if dictionary.keys.contains(where: isFilterValueKey) {
      dictionaries.append(dictionary)
    }
  }

  private func nestedDictionary(named name: String, in dictionary: [String: Any]) -> [String: Any]? {
    guard let value = dictionary.first(where: { normalizedKey($0.key) == normalizedKey(name) })?.value else {
      return nil
    }
    return value as? [String: Any]
  }

  private func filterValue(for parameter: FilterEditParameter, in dictionary: [String: Any]) -> Double? {
    let acceptedKeys = [
      normalizedKey(parameter.apiKey),
      normalizedKey(parameter.rawValue),
    ]

    guard let value = dictionary.first(where: { acceptedKeys.contains(normalizedKey($0.key)) })?.value else {
      return nil
    }

    if let number = value as? NSNumber {
      return number.doubleValue
    }
    if let string = value as? String {
      return Double(string)
    }
    return nil
  }

  private func isFilterValueKey(_ key: String) -> Bool {
    FilterEditParameter.allCases.contains { parameter in
      normalizedKey(key) == normalizedKey(parameter.apiKey) || normalizedKey(key) == normalizedKey(parameter.rawValue)
    }
  }

  private func normalizedKey(_ key: String) -> String {
    key.filter(\.isLetter).lowercased()
  }

  private func dictionaryValue(
    for key: CFString,
    in dictionary: [AnyHashable: Any]?
  ) -> [AnyHashable: Any]? {
    dictionary?[AnyHashable(key)] as? [AnyHashable: Any]
  }

  private func stringValue(
    for key: CFString,
    in dictionary: [AnyHashable: Any]?
  ) -> String? {
    guard let value = value(for: key, in: dictionary) else { return nil }
    if let string = value as? String, string.isEmpty == false {
      return string
    }
    return nil
  }

  private func doubleValue(
    for key: CFString,
    in dictionary: [AnyHashable: Any]?
  ) -> Double? {
    guard let value = value(for: key, in: dictionary) else { return nil }
    if let number = value as? NSNumber {
      return number.doubleValue
    }
    if let double = value as? Double {
      return double
    }
    if let string = value as? String {
      return Double(string)
    }
    return nil
  }

  private func value(
    for key: CFString,
    in dictionary: [AnyHashable: Any]?
  ) -> Any? {
    dictionary?[AnyHashable(key)]
  }

  private func numericText(from value: Any) -> String? {
    if let number = value as? NSNumber {
      return number.doubleValue.formatted(.number.precision(.fractionLength(0 ... 2)))
    }
    if let double = value as? Double {
      return double.formatted(.number.precision(.fractionLength(0 ... 2)))
    }
    if let string = value as? String, string.isEmpty == false {
      return string
    }
    return nil
  }
}

extension FilterDetailMetadata {
  nonisolated static let empty = FilterDetailMetadata(
    camera: nil,
    lens: nil,
    focalLength: nil,
    aperture: nil,
    shutterSpeed: nil,
    iso: nil
  )
}
