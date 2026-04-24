import Foundation

nonisolated struct RequestQuery: ExpressibleByDictionaryLiteral, Sendable {
  static let empty = RequestQuery()

  private let values: [String: String]

  init(_ values: [String: String] = [:]) {
    self.values = values
  }

  init(dictionaryLiteral elements: (String, String)...) {
    self.values = Dictionary(uniqueKeysWithValues: elements)
  }

  var isEmpty: Bool {
    values.isEmpty
  }

  var urlQueryItems: [URLQueryItem] {
    values.keys.sorted().map { key in
      URLQueryItem(name: key, value: values[key])
    }
  }
}
