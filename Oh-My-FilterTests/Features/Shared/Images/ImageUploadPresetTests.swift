import Testing
@testable import Oh_My_Filter

struct ImageUploadPresetTests {
  @Test("upload presets expose configured limits and file extensions")
  func presetConfiguration() {
    #expect(ImageUploadPreset.filter.supportedFileExtensions == ["jpg", "png", "jpeg"])
    #expect(ImageUploadPreset.filter.maxBytes == 2_000_000)
    #expect(ImageUploadPreset.filter.maxCount == 2)

    #expect(ImageUploadPreset.profile.supportedFileExtensions == ["jpg", "png", "jpeg"])
    #expect(ImageUploadPreset.profile.maxBytes == 1_000_000)
    #expect(ImageUploadPreset.profile.maxCount == 1)
    #expect(ImageUploadPreset.profile.multipartFieldName == "profile")

    #expect(ImageUploadPreset.communityPost.supportedFileExtensions == [
      "jpg",
      "png",
      "jpeg",
      "gif",
      "webp",
      "mp4",
      "mov",
      "avi",
      "mkv",
      "wmv",
    ])
    #expect(ImageUploadPreset.communityPost.maxBytes == 5_000_000)
    #expect(ImageUploadPreset.communityPost.maxCount == 5)

    #expect(ImageUploadPreset.chat.supportedFileExtensions == ["jpg", "png", "jpeg", "gif", "pdf"])
    #expect(ImageUploadPreset.chat.maxBytes == 50_000_000)
    #expect(ImageUploadPreset.chat.maxCount == 5)
  }
}
