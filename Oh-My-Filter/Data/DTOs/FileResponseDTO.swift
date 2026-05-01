import Foundation

nonisolated struct FileResponseDTO: Decodable, Equatable, Sendable {
  let files: [String]
}
