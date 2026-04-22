import CoreGraphics
import Testing
@testable import Oh_My_Filter

struct TypographyTokenTests {
  @Test("Typography tokens mirror the Figma asset catalog")
  func registersTypographyCatalog() {
    #expect(TypographyToken.allCases.count == 10)
    #expect(TypographyToken.pretendardTitle1.pointSize == CGFloat(20))
    #expect(TypographyToken.pretendardCaption3.pointSize == CGFloat(8))
    #expect(TypographyToken.mulgyeolTitle1.fontName == "HakgyoansimMulgyeolB")
  }

  @Test(arguments: TypographyToken.allCases)
  func typographyMetadataLooksValid(token: TypographyToken) {
    #expect(token.figmaName.contains("/"))
    #expect(token.familyDisplayName.isEmpty == false)
    #expect(token.fontName.isEmpty == false)
    #expect(token.pointSize > CGFloat.zero)
    #expect(token.sampleText.isEmpty == false)
  }
}
