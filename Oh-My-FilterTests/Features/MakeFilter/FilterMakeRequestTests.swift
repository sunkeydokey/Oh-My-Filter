import Foundation
import Testing
@testable import Oh_My_Filter

struct FilterMakeRequestTests {
  @Test("filter creation request encodes documented server keys")
  func encodesDocumentedServerKeys() throws {
    var values = FilterEditParameter.defaultValues
    values[.sharpness] = 1.25
    values[.noiseReduction] = 0.4
    values[.blackPoint] = 0.2

    let draft = FilterMakeDraft(
      name: "Soft Mood",
      category: .portrait,
      introduction: "Warm portrait tone",
      price: 1_000,
      representativeImageData: Data([0x01]),
      photoMetadata: FilterDetailMetadata(
        camera: "Apple iPhone",
        lens: "Wide",
        focalLength: "26.0 mm",
        aperture: "f 1.8",
        shutterSpeed: "1/120",
        iso: "100"
      ),
      filterParameterValues: values
    )
    let request = FilterMakeRequest(draft: draft, files: ["/data/filters/original.jpg", "/data/filters/filtered.jpg"])

    let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
    let filterValues = try #require(json?["filter_values"] as? [String: Any])
    let metadata = try #require(json?["photo_metadata"] as? [String: Any])

    #expect(json?["category"] as? String == "인물")
    #expect(json?["title"] as? String == "Soft Mood")
    #expect(json?["description"] as? String == "Warm portrait tone")
    #expect(json?["price"] as? Int == 1_000)
    #expect(json?["files"] as? [String] == ["/data/filters/original.jpg", "/data/filters/filtered.jpg"])
    #expect(filterValues["sharpness"] as? Double == 1.25)
    #expect(filterValues["sharpen"] == nil)
    #expect(filterValues["noise_reduction"] as? Double == 0.4)
    #expect(filterValues["black_point"] as? Double == 0.2)
    #expect(metadata["lens_info"] as? String == "Wide")
    #expect(metadata["focal_length"] as? Int == 26)
    #expect(metadata["aperture"] as? Double == 1.8)
    #expect(metadata["iso"] as? Int == 100)
    #expect(metadata["shutter_speed"] as? String == "1/120")
  }
}
