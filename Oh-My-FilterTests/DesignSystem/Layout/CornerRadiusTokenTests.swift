import CoreGraphics
import Testing
@testable import Oh_My_Filter

struct CornerRadiusTokenTests {
  @Test("Section radius uses the exported Figma token")
  func registersSectionRadius() {
    #expect(CornerRadiusToken.section.figmaName == "Radius/Section")
    #expect(CornerRadiusToken.section.value == CGFloat(15))
  }
}
