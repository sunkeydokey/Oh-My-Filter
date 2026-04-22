import Testing
@testable import Oh_My_Filter

struct IconTokenTests {
  @Test("Icon tokens register every Figma asset")
  func registersIconCatalog() {
    #expect(IconToken.allCases.count == 38)
    #expect(IconToken.back.symbolName == "chevron.left")
    #expect(IconToken.settings.groupTitle == "Utility")
    #expect(IconToken.magicFilled.displayName == "Magic Fill")
  }

  @Test(arguments: IconToken.allCases)
  func iconMetadataLooksValid(token: IconToken) {
    #expect(token.figmaName.contains("Icons/"))
    #expect(token.symbolName.isEmpty == false)
    #expect(token.displayName.isEmpty == false)
    #expect(token.groupTitle.isEmpty == false)
  }
}
