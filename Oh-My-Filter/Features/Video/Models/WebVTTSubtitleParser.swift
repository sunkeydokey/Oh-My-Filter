import Foundation

nonisolated enum WebVTTSubtitleParser {
  static func parse(_ string: String) -> [VideoSubtitleCue] {
    let normalized = string.replacing("\r\n", with: "\n").replacing("\r", with: "\n")
    let blocks = normalized.components(separatedBy: "\n\n")

    return blocks.compactMap { block in
      parseCue(block)
    }
  }

  private static func parseCue(_ block: String) -> VideoSubtitleCue? {
    let lines = block
      .split(separator: "\n", omittingEmptySubsequences: false)
      .map(String.init)

    guard let timingIndex = lines.firstIndex(where: { $0.contains("-->") }) else {
      return nil
    }

    let timingParts = lines[timingIndex].components(separatedBy: "-->")
    guard timingParts.count == 2 else { return nil }

    let startToken = timingParts[0].trimmingCharacters(in: .whitespacesAndNewlines)
    let endToken = timingParts[1]
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .split(separator: " ")
      .first
      .map(String.init)

    guard
      let endToken,
      let startTime = parseTimestamp(startToken),
      let endTime = parseTimestamp(endToken),
      endTime > startTime
    else {
      return nil
    }

    let text = lines
      .dropFirst(timingIndex + 1)
      .joined(separator: "\n")
      .trimmingCharacters(in: .whitespacesAndNewlines)

    guard text.isEmpty == false else { return nil }

    return VideoSubtitleCue(startTime: startTime, endTime: endTime, text: text)
  }

  private static func parseTimestamp(_ token: String) -> Double? {
    let timeAndFraction = token.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
    let secondSeparatorParts: [Substring]

    if timeAndFraction.count == 2 {
      secondSeparatorParts = timeAndFraction
    } else {
      secondSeparatorParts = token.split(separator: ",", maxSplits: 1, omittingEmptySubsequences: false)
    }

    guard secondSeparatorParts.count == 2 else { return nil }

    let timeParts = secondSeparatorParts[0].split(separator: ":").compactMap { Double($0) }
    guard timeParts.count == 2 || timeParts.count == 3 else { return nil }

    let fraction = String(secondSeparatorParts[1].prefix(3))
    guard let milliseconds = Double(fraction.padding(toLength: 3, withPad: "0", startingAt: 0)) else {
      return nil
    }

    let baseSeconds: Double
    if timeParts.count == 3 {
      baseSeconds = timeParts[0] * 3600 + timeParts[1] * 60 + timeParts[2]
    } else {
      baseSeconds = timeParts[0] * 60 + timeParts[1]
    }

    return baseSeconds + milliseconds / 1000
  }
}
