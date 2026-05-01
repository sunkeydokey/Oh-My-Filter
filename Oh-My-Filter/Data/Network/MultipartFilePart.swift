import Foundation

nonisolated struct MultipartFilePart: Equatable, Sendable {
  let fieldName: String
  let fileName: String
  let mimeType: String
  let data: Data

  init(
    fieldName: String,
    fileName: String,
    mimeType: String,
    data: Data
  ) {
    self.fieldName = fieldName
    self.fileName = fileName
    self.mimeType = mimeType
    self.data = data
  }
}

nonisolated struct MultipartFormData: Equatable, Sendable {
  let contentType: String
  let body: Data
}

nonisolated enum MultipartFormDataBuilder {
  static func build(
    files: [MultipartFilePart],
    boundary: String = "Boundary-\(UUID().uuidString)"
  ) -> MultipartFormData {
    var body = Data()

    for file in files {
      append("--\(boundary)\r\n", to: &body)
      append("Content-Disposition: form-data; name=\"\(file.fieldName)\"; filename=\"\(file.fileName)\"\r\n", to: &body)
      append("Content-Type: \(file.mimeType)\r\n\r\n", to: &body)
      body.append(file.data)
      append("\r\n", to: &body)
    }

    append("--\(boundary)--\r\n", to: &body)

    return MultipartFormData(
      contentType: "\(ContentType.multipart.rawValue); boundary=\(boundary)",
      body: body
    )
  }

  private static func append(_ string: String, to data: inout Data) {
    data.append(Data(string.utf8))
  }
}
