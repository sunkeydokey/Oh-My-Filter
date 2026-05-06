import Foundation

nonisolated struct FilterDetail: Equatable, Identifiable, Sendable {
  let id: String
  let title: String
  let category: String?
  let introduction: String?
  let description: String
  let originalImageURL: URL?
  let fallbackFilteredImageURL: URL?
  let creator: FilterDetailCreator
  let metadata: FilterDetailMetadata
  let filterValues: FilterValues
  let comments: [Comment]
  let isDownloaded: Bool
  let isLiked: Bool
  let likeCount: Int
  let buyerCount: Int
  let price: Int
  let hashTags: [String]
  let createdAt: String?
  let updatedAt: String?

  var buttonTitle: String {
    isDownloaded ? "구매완료" : "결제하기"
  }

  var priceText: String {
    price.formatted(.number)
  }

  var downloadCountText: String {
    buyerCount.formatted(.number)
  }

  var likeCountText: String {
    likeCount.formatted(.number)
  }
}

nonisolated struct FilterDetailCreator: Equatable, Sendable {
  let id: String
  let nick: String
  let name: String?
  let profileImageURL: URL?
  let introduction: String?
  let hashTags: [String]

  var displayName: String {
    name ?? nick
  }
}

nonisolated struct FilterDetailMetadata: Equatable, Hashable, Sendable {
  let camera: String?
  let lens: String?
  let focalLength: String?
  let aperture: String?
  let shutterSpeed: String?
  let iso: String?

  var displayRows: [(String, String)] {
    [
      ("Camera", camera),
      ("Lens", lens),
      ("Focal", focalLength),
      ("Aperture", aperture),
      ("Shutter", shutterSpeed),
      ("ISO", iso),
    ].compactMap { label, value in
      guard let value, value.isEmpty == false else { return nil }
      return (label, value)
    }
  }

  var headerValue: String {
    camera ?? "EXIF"
  }
}

nonisolated struct FilterValues: Equatable, Sendable {
  let brightness: Double
  let contrast: Double
  let saturation: Double
  let exposure: Double
  let sharpen: Double
  let blur: Double
  let vignette: Double
  let noiseReduction: Double
  let highlights: Double
  let shadows: Double
  let temperature: Double
  let blackPoint: Double

  static let neutral = FilterValues(
    brightness: 0,
    contrast: 1,
    saturation: 1,
    exposure: 0,
    sharpen: 0,
    blur: 0,
    vignette: 0,
    noiseReduction: 0,
    highlights: 0,
    shadows: 0,
    temperature: 5500,
    blackPoint: 0
  )

  var displayItems: [FilterValueDisplayItem] {
    [
      .init(title: "Bright", value: brightness),
      .init(title: "Contrast", value: contrast),
      .init(title: "Saturation", value: saturation),
      .init(title: "Exposure", value: exposure),
      .init(title: "Sharpen", value: sharpen),
      .init(title: "Blur", value: blur),
      .init(title: "Vignette", value: vignette),
      .init(title: "Noise", value: noiseReduction),
      .init(title: "Highlight", value: highlights),
      .init(title: "Shadow", value: shadows),
      .init(title: "Temp", value: temperature),
      .init(title: "Black Point", value: blackPoint),
    ]
  }
}

nonisolated struct FilterValueDisplayItem: Equatable, Identifiable, Sendable {
  let title: String
  let value: Double

  var id: String { title }

  var valueText: String {
    value.formatted(.number.precision(.fractionLength(0 ... 2)))
  }
}
