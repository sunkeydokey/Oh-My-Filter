import Testing
@testable import Oh_My_Filter

struct FilterDetailMetadataTests {
  @Test("display rows omit nil and empty values")
  func displayRowsOmitMissingValues() {
    let metadata = FilterDetailMetadata(
      camera: "Apple iPhone 16 Pro",
      lens: "",
      focalLength: "26 mm",
      aperture: nil,
      shutterSpeed: "1/120",
      iso: "400"
    )

    #expect(metadata.displayRows.map(\.0) == ["Camera", "Focal", "Shutter", "ISO"])
    #expect(metadata.headerValue == "Apple iPhone 16 Pro")
  }

  @Test("header falls back to EXIF when camera is missing")
  func headerFallsBackToExif() {
    let metadata = FilterDetailMetadata(
      camera: nil,
      lens: nil,
      focalLength: nil,
      aperture: nil,
      shutterSpeed: nil,
      iso: nil
    )

    #expect(metadata.displayRows.isEmpty)
    #expect(metadata.headerValue == "EXIF")
  }
}
