import Foundation

nonisolated enum FilterEditParameter: String, CaseIterable, Hashable, Sendable {
  case brightness
  case exposure
  case contrast
  case saturation
  case sharpness
  case blur
  case vignette
  case noiseReduction
  case highlights
  case shadows
  case temperature
  case blackPoint

  static var defaultValues: [FilterEditParameter: Double] {
    Dictionary(
      uniqueKeysWithValues: allCases.map { parameter in
        (parameter, parameter.defaultValue)
      }
    )
  }

  static func filterValues(from values: [FilterEditParameter: Double]) -> FilterValues {
    FilterValues(
      brightness: value(for: .brightness, in: values),
      contrast: value(for: .contrast, in: values),
      saturation: value(for: .saturation, in: values),
      exposure: value(for: .exposure, in: values),
      sharpen: value(for: .sharpness, in: values),
      blur: value(for: .blur, in: values),
      vignette: value(for: .vignette, in: values),
      noiseReduction: value(for: .noiseReduction, in: values),
      highlights: value(for: .highlights, in: values),
      shadows: value(for: .shadows, in: values),
      temperature: value(for: .temperature, in: values),
      blackPoint: value(for: .blackPoint, in: values)
    )
  }

  private static func value(
    for parameter: FilterEditParameter,
    in values: [FilterEditParameter: Double]
  ) -> Double {
    values[parameter, default: parameter.defaultValue]
  }

  var apiKey: String {
    switch self {
    case .brightness:
      "brightness"
    case .exposure:
      "exposure"
    case .contrast:
      "contrast"
    case .saturation:
      "saturation"
    case .sharpness:
      "sharpness"
    case .blur:
      "blur"
    case .vignette:
      "vignette"
    case .noiseReduction:
      "noise_reduction"
    case .highlights:
      "highlights"
    case .shadows:
      "shadows"
    case .temperature:
      "temperature"
    case .blackPoint:
      "black_point"
    }
  }

  var label: String {
    switch self {
    case .brightness:
      "Brightness"
    case .exposure:
      "Exposure"
    case .contrast:
      "Contrast"
    case .saturation:
      "Saturation"
    case .sharpness:
      "Sharpness"
    case .blur:
      "Blur"
    case .vignette:
      "Vignette"
    case .noiseReduction:
      "Noise"
    case .highlights:
      "Highlights"
    case .shadows:
      "Shadows"
    case .temperature:
      "Temperature"
    case .blackPoint:
      "Black Point"
    }
  }

  var range: ClosedRange<Double> {
    switch self {
    case .brightness:
      -1 ... 1
    case .exposure:
      -2 ... 2
    case .contrast, .saturation:
      0 ... 2
    case .sharpness:
      0 ... 2
    case .blur:
      0 ... 20
    case .vignette, .noiseReduction, .blackPoint:
      0 ... 1
    case .highlights, .shadows:
      -1 ... 1
    case .temperature:
      2_000 ... 10_000
    }
  }

  var defaultValue: Double {
    switch self {
    case .contrast, .saturation:
      1
    case .temperature:
      5_500
    default:
      0
    }
  }

  var step: Double {
    switch self {
    case .temperature:
      100
    case .blur:
      0.5
    default:
      0.01
    }
  }

  var rangeLabelMin: String {
    displayText(for: range.lowerBound)
  }

  var rangeLabelMax: String {
    displayText(for: range.upperBound)
  }

  var descriptionText: String {
    switch self {
    case .brightness:
      "전체 밝기를 부드럽게 조정할 수 있어요"
    case .exposure:
      "빛의 노출감을 자연스럽게 조정할 수 있어요"
    case .contrast:
      "밝고 어두운 영역의 대비를 조정할 수 있어요"
    case .saturation:
      "색의 선명도를 조정할 수 있어요"
    case .sharpness:
      "이미지의 또렷함을 조정할 수 있어요"
    case .blur:
      "부드러운 흐림 정도를 조정할 수 있어요"
    case .vignette:
      "가장자리 음영을 조정할 수 있어요"
    case .noiseReduction:
      "거친 노이즈를 줄이는 정도를 조정할 수 있어요"
    case .highlights:
      "밝은 영역의 톤을 조정할 수 있어요"
    case .shadows:
      "어두운 영역의 톤을 조정할 수 있어요"
    case .temperature:
      "색온도를 따뜻하거나 차갑게 조정할 수 있어요"
    case .blackPoint:
      "검은색 기준점을 조정할 수 있어요"
    }
  }

  func clamped(_ value: Double) -> Double {
    min(max(value, range.lowerBound), range.upperBound)
  }

  func displayText(for value: Double) -> String {
    let displayValue = value * displayScale
    if self == .temperature {
      return "\(Int(displayValue.rounded()))\(displayUnit)"
    }

    let formattedValue = displayValue.formatted(.number.precision(.fractionLength(displayFractionLength)))
    return "\(formattedValue)\(displayUnit)"
  }

  private var displayScale: Double {
    switch self {
    case .brightness, .contrast, .saturation, .highlights, .shadows, .blackPoint:
      100
    default:
      1
    }
  }

  private var displayUnit: String {
    switch self {
    case .contrast, .saturation, .highlights, .shadows, .blackPoint:
      "%"
    case .temperature:
      "K"
    default:
      ""
    }
  }

  private var displayFractionLength: ClosedRange<Int> {
    switch self {
    case .temperature:
      0 ... 0
    case .brightness, .contrast, .saturation, .highlights, .shadows, .blackPoint:
      0 ... 0
    default:
      0 ... 2
    }
  }

  var icon: IconToken {
    switch self {
    case .brightness:
      .sparkle
    case .exposure:
      .gauge
    case .contrast:
      .controls
    case .saturation:
      .mood
    case .sharpness:
      .warning
    case .blur:
      .texture
    case .vignette:
      .grid
    case .noiseReduction:
      .progress
    case .highlights:
      .sparkle
    case .shadows:
      .controls
    case .temperature:
      .temperature
    case .blackPoint:
      .settings
    }
  }
}
