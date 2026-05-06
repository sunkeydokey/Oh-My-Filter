import Foundation

nonisolated protocol SharedCommentServicing: Sendable {
  func createComment<Router: ApiRouter>(
    router: Router,
    parentCommentID: String?,
    content: String
  ) async throws -> CommentReply
}

nonisolated enum SharedCommentServiceError: Error, Equatable, LocalizedError, Sendable {
  case invalidRequest
  case invalidResponse
  case notFound
  case permissionDenied
  case serverError
  case transport

  var errorDescription: String? {
    switch self {
    case .invalidRequest:
      "댓글 내용을 확인해 주세요."
    case .invalidResponse:
      "댓글 정보를 해석할 수 없습니다."
    case .notFound:
      "댓글을 작성할 대상을 찾을 수 없습니다."
    case .permissionDenied:
      "댓글 작성 권한이 없습니다."
    case .serverError:
      "잠시 후 다시 시도해 주세요."
    case .transport:
      "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
    }
  }
}

actor LiveSharedCommentService: SharedCommentServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let decoder: JSONDecoder

  init(
    networkManager: any AuthenticatedNetworkManaging,
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.networkManager = networkManager
    let configuredDecoder = decoder
    configuredDecoder.keyDecodingStrategy = .convertFromSnakeCase
    self.decoder = configuredDecoder
  }

  @MainActor
  init(decoder: JSONDecoder = JSONDecoder()) {
    self.init(networkManager: AuthenticatedNetworkManager(), decoder: decoder)
  }

  func createComment<Router: ApiRouter>(
    router: Router,
    parentCommentID: String?,
    content: String
  ) async throws -> CommentReply {
    guard content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
      throw SharedCommentServiceError.invalidRequest
    }

    let body = CommentRequestDTO(parent_comment_id: parentCommentID, content: content)
    let response: NetworkResponse
    do {
      response = try await networkManager.request(router, body: body, parameters: .empty)
    } catch let error as NetworkError {
      throw mappedNetworkError(error)
    } catch {
      throw SharedCommentServiceError.transport
    }

    return try decode(CommentReplyDTO.self, from: response).toDomain()
  }

  private func decode<DTO: Decodable>(_ type: DTO.Type, from response: NetworkResponse) throws -> DTO {
    switch response.statusCode {
    case 200 ..< 300:
      do {
        return try decoder.decode(type, from: response.data)
      } catch {
        throw SharedCommentServiceError.invalidResponse
      }
    case 400:
      throw SharedCommentServiceError.invalidRequest
    case 404:
      throw SharedCommentServiceError.notFound
    case 445:
      throw SharedCommentServiceError.permissionDenied
    default:
      throw SharedCommentServiceError.serverError
    }
  }

  private func mappedNetworkError(_ error: NetworkError) -> SharedCommentServiceError {
    switch error {
    case .invalidRequest:
      .invalidRequest
    case .invalidResponse:
      .invalidResponse
    case .transport:
      .transport
    }
  }
}
