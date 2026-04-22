import CoreGraphics

/// Tokens imported from Figma file `oPqetVKRN2ukzdLpYKr11h`, node `2284:1421`.
enum CornerRadiusToken: Sendable {
  case section

  var figmaName: String {
    switch self {
    case .section:
      "Radius/Section"
    }
  }

  var value: CGFloat {
    switch self {
    case .section:
      15
    }
  }
}
