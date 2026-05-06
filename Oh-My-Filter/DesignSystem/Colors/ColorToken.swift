import SwiftUI

/// Tokens imported from Figma file `oPqetVKRN2ukzdLpYKr11h`, node `2284:1286`.
enum ColorToken: String, CaseIterable, Sendable {
  case brandBlackSprout = "BrandBlackSprout"
  case brandDeepSprout = "BrandDeepSprout"
  case mainAccent = "MainAccent"
  case sesacFilterDeepTurquoise = "SESACFilterDeepTurquoise"
  case sesacFilterBrightTurquoise = "SESACFilterBrightTurquoise"
  case grayScale0 = "GrayScale0"
  case grayScale15 = "GrayScale15"
  case grayScale30 = "GrayScale30"
  case grayScale45 = "GrayScale45"
  case grayScale60 = "GrayScale60"
  case grayScale75 = "GrayScale75"
  case grayScale90 = "GrayScale90"
  case grayScale100 = "GrayScale100"

  var figmaName: String {
    switch self {
    case .brandBlackSprout:
      "Brand/BlackSprout"
    case .brandDeepSprout:
      "Brand/DeepSprout"
    case .mainAccent:
      "Main/Accent"
    case .sesacFilterDeepTurquoise:
      "SESAC_Filter/DeepTurquoise"
    case .sesacFilterBrightTurquoise:
      "SESAC_Filter/BrightTurquoise"
    case .grayScale0:
      "GrayScale/0"
    case .grayScale15:
      "GrayScale/15"
    case .grayScale30:
      "GrayScale/30"
    case .grayScale45:
      "GrayScale/45"
    case .grayScale60:
      "GrayScale/60"
    case .grayScale75:
      "GrayScale/75"
    case .grayScale90:
      "GrayScale/90"
    case .grayScale100:
      "GrayScale/100"
    }
  }

  var hexValue: String {
    switch self {
    case .brandBlackSprout:
      "#1F2527"
    case .brandDeepSprout, .sesacFilterDeepTurquoise:
      "#293235"
    case .mainAccent:
      "#BBD68C"
    case .sesacFilterBrightTurquoise:
      "#315C6B"
    case .grayScale0:
      "#FFFFFF"
    case .grayScale15:
      "#F9F9F9"
    case .grayScale30:
      "#EAEAEA"
    case .grayScale45:
      "#D8D6D7"
    case .grayScale60:
      "#ABABAE"
    case .grayScale75:
      "#6A6A6E"
    case .grayScale90:
      "#434347"
    case .grayScale100:
      "#0B0B0B"
    }
  }

  var color: Color {
    Color(rawValue)
  }
}
