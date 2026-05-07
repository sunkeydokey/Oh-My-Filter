import Testing
@testable import Oh_My_Filter

struct WebVTTSubtitleParserTests {
  @Test("parses multiple cues")
  func parsesMultipleCues() {
    let cues = WebVTTSubtitleParser.parse(
      """
      WEBVTT

      00:00:01.000 --> 00:00:03.000
      첫 번째 자막

      00:00:04.500 --> 00:00:06.000
      두 번째 자막
      """
    )

    #expect(cues == [
      VideoSubtitleCue(startTime: 1, endTime: 3, text: "첫 번째 자막"),
      VideoSubtitleCue(startTime: 4.5, endTime: 6, text: "두 번째 자막"),
    ])
  }

  @Test("preserves multiline cue text")
  func preservesMultilineCueText() {
    let cues = WebVTTSubtitleParser.parse(
      """
      WEBVTT

      00:00:01.000 --> 00:00:03.000
      첫 번째 줄
      두 번째 줄
      """
    )

    #expect(cues.first?.text == "첫 번째 줄\n두 번째 줄")
  }

  @Test("ignores invalid cues")
  func ignoresInvalidCues() {
    let cues = WebVTTSubtitleParser.parse(
      """
      WEBVTT

      invalid
      자막

      00:00:02.000 --> 00:00:01.000
      역방향 자막

      00:00:03.000 --> 00:00:04.000
      정상 자막
      """
    )

    #expect(cues == [
      VideoSubtitleCue(startTime: 3, endTime: 4, text: "정상 자막")
    ])
  }

  @Test("parses minute second timestamps")
  func parsesMinuteSecondTimestamps() {
    let cues = WebVTTSubtitleParser.parse(
      """
      WEBVTT

      01:02.250 --> 01:04.000
      짧은 형식
      """
    )

    #expect(cues == [
      VideoSubtitleCue(startTime: 62.25, endTime: 64, text: "짧은 형식")
    ])
  }
}
