import Testing
@testable import Oh_My_Filter

struct ColorTokenTests {
  @Test("Figma color palette is fully registered")
  func registersEveryColorToken() {
    #expect(ColorToken.allCases.count == 12)
    #expect(Set(ColorToken.allCases.map(\.rawValue)).count == ColorToken.allCases.count)
    #expect(ColorToken.brandBlackSprout.figmaName == "Brand/BlackSprout")
    #expect(ColorToken.grayScale100.hexValue == "#0B0B0B")
    #expect(ColorToken.sesacFilterBrightTurquoise.hexValue == "#315C6B")
  }

  @Test(arguments: ColorToken.allCases)
  func tokenMetadataLooksValid(token: ColorToken) {
    #expect(token.rawValue.isEmpty == false)
    #expect(token.figmaName.contains("/"))
    #expect(token.hexValue.count == 7)
    #expect(token.hexValue.hasPrefix("#"))
  }
}
