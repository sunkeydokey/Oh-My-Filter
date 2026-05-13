import Foundation
import OSLog

actor LiveCommunityService: CommunityServicing {
  private let networkManager: any AuthenticatedNetworkManaging
  private let sharedCommentService: any SharedCommentServicing
  private let userSessionStore: any UserSessionStoring
  private let decoder: JSONDecoder
  private let imageUploadUseCase: any ImageUploadUseCase
  private static let defaultLatitude = 37.654215
  private static let defaultLongitude = 127.049914
  private static let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "Oh-My-Filter",
    category: "CommunityAPI"
  )

  init(
    networkManager: any AuthenticatedNetworkManaging,
    decoder: JSONDecoder = JSONDecoder(),
    imageUploadUseCase: any ImageUploadUseCase = LiveImageUploadUseCase(),
    sharedCommentService: (any SharedCommentServicing)? = nil,
    userSessionStore: any UserSessionStoring = AppUserSessionStore()
  ) {
    self.networkManager = networkManager
    self.sharedCommentService = sharedCommentService ?? LiveSharedCommentService(networkManager: networkManager, decoder: decoder)
    self.userSessionStore = userSessionStore
    let configuredDecoder = decoder
    configuredDecoder.keyDecodingStrategy = .convertFromSnakeCase
    self.decoder = configuredDecoder
    self.imageUploadUseCase = imageUploadUseCase
  }

  @MainActor
  init(decoder: JSONDecoder = JSONDecoder()) {
    self.init(networkManager: AuthenticatedNetworkManager(), decoder: decoder)
  }

  func loadCurrentUserID() async throws -> String {
    guard let currentUserID = userSessionStore.currentUserID(),
          currentUserID.isEmpty == false else {
      throw CommunityServiceError.invalidResponse
    }
    return currentUserID
  }

  func uploadPostFiles(selections: [PhotoPickerUploadSelection]) async throws -> [String] {
    guard selections.isEmpty == false else { return [] }

    do {
      let fileParts = try await imageUploadUseCase.multipartFiles(from: selections, preset: .communityPost)
      Self.logger.debug("[CommunityPostUpload] multipart extensions=\(fileParts.fileExtensionsDescription, privacy: .public)")
      let response = try await networkManager.request(CommunityApiRouter.uploadFiles, multipartFiles: fileParts)
      let files = try decode(FileResponseDTO.self, from: response).files
      Self.logger.debug("[CommunityPostUpload] uploaded file extensions=\(files.fileExtensionsDescription, privacy: .public)")
      return files
    } catch let error as CommunityServiceError {
      throw error
    } catch let error as ImageCompressionError {
      throw mappedImageCompressionError(error)
    } catch let error as NetworkError {
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [CommunityAPI] upload failed error=\(String(describing: error), privacy: .public)")
      throw CommunityServiceError.transport
    }
  }

  func createPost(draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    let files = try await uploadPostFiles(selections: newImages)
    let body = postRequestBody(draft: draft, files: files)
    let response = try await requestWithBody(CommunityApiRouter.createPost, body: body, parameters: .empty)
    return try decode(CommunityPostDTO.self, from: response).toDomain()
  }

  func loadPosts(nextCursor: String?, limit: Int, orderBy: String) async throws -> CommunityPostPage {
    guard limit > 0 else { throw CommunityServiceError.invalidRequest }

    let response = try await request(
      CommunityApiRouter.posts,
      parameters: pageQuery(nextCursor: nextCursor, limit: limit, extra: ["order_by": orderBy])
    )
    return try decode(CommunityPostPageDTO.self, from: response).toDomain()
  }

  func searchPosts(title: String) async throws -> [CommunityPost] {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    let response = try await request(
      CommunityApiRouter.searchPosts,
      parameters: trimmedTitle.isEmpty ? .empty : RequestQuery(["title": trimmedTitle])
    )
    return try decode(CommunityPostListDTO.self, from: response).toDomain()
  }

  func loadLikedPosts(nextCursor: String?, limit: Int) async throws -> CommunityPostPage {
    guard limit > 0 else { throw CommunityServiceError.invalidRequest }

    let response = try await request(
      CommunityApiRouter.likedPosts,
      parameters: pageQuery(nextCursor: nextCursor, limit: limit)
    )
    return try decode(CommunityPostPageDTO.self, from: response).toDomain()
  }

  func loadPostDetail(postID: String) async throws -> CommunityPost {
    guard postID.isEmpty == false else { throw CommunityServiceError.invalidRequest }

    let response = try await request(CommunityApiRouter.postDetail(postID: postID), parameters: .empty)
    return try decode(CommunityPostDTO.self, from: response).toDomain()
  }

  func updatePost(postID: String, draft: CommunityPostDraft, newImages: [PhotoPickerUploadSelection]) async throws -> CommunityPost {
    guard postID.isEmpty == false else { throw CommunityServiceError.invalidRequest }

    let uploadedFiles = try await uploadPostFiles(selections: newImages)
    let body = postRequestBody(draft: draft, files: draft.existingFilePaths + uploadedFiles)
    let response = try await requestWithBody(CommunityApiRouter.updatePost(postID: postID), body: body, parameters: .empty)
    return try decode(CommunityPostDTO.self, from: response).toDomain()
  }

  func deletePost(postID: String) async throws {
    guard postID.isEmpty == false else { throw CommunityServiceError.invalidRequest }

    let response = try await request(CommunityApiRouter.deletePost(postID: postID), parameters: .empty)
    try validateEmptyResponse(response)
  }

  func toggleLike(postID: String, status: Bool) async throws -> Bool {
    guard postID.isEmpty == false else { throw CommunityServiceError.invalidRequest }

    let body = CommunityPostLikeRequestDTO(like_status: status)
    let response = try await requestWithBody(CommunityApiRouter.like(postID: postID), body: body, parameters: .empty)
    return try decode(CommunityPostLikeResponseDTO.self, from: response).likeStatus
  }

  func createComment(postID: String, parentCommentID: String?, content: String) async throws -> CommunityReply {
    guard postID.isEmpty == false, content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
      throw CommunityServiceError.invalidRequest
    }

    do {
      return try await sharedCommentService.createComment(
        router: CommunityApiRouter.createComment(postID: postID),
        parentCommentID: parentCommentID,
        content: content
      )
    } catch let error as SharedCommentServiceError {
      throw mappedCommentError(error)
    }
  }

  func updateComment(postID: String, commentID: String, content: String) async throws -> CommunityReply {
    guard postID.isEmpty == false, commentID.isEmpty == false else {
      throw CommunityServiceError.invalidRequest
    }

    do {
      return try await sharedCommentService.updateComment(
        router: CommunityApiRouter.updateComment(postID: postID, commentID: commentID),
        content: content
      )
    } catch let error as SharedCommentServiceError {
      throw mappedCommentError(error)
    }
  }

  func deleteComment(postID: String, commentID: String) async throws {
    guard postID.isEmpty == false, commentID.isEmpty == false else {
      throw CommunityServiceError.invalidRequest
    }

    do {
      try await sharedCommentService.deleteComment(
        router: CommunityApiRouter.deleteComment(postID: postID, commentID: commentID)
      )
    } catch let error as SharedCommentServiceError {
      throw mappedCommentError(error)
    }
  }

  func loadVideos(nextCursor: String?, limit: Int) async throws -> CommunityVideoPage {
    guard limit > 0 else { throw CommunityServiceError.invalidRequest }

    let response = try await request(VideoApiRouter.list, parameters: pageQuery(nextCursor: nextCursor, limit: limit))
    return try decode(CommunityVideoPageDTO.self, from: response).toDomain()
  }

  private func postRequestBody(draft: CommunityPostDraft, files: [String]) -> CommunityPostRequestDTO {
    CommunityPostRequestDTO(
      category: draft.category.trimmingCharacters(in: .whitespacesAndNewlines),
      title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
      content: draft.content.trimmingCharacters(in: .whitespacesAndNewlines),
      latitude: Self.defaultLatitude,
      longitude: Self.defaultLongitude,
      files: files
    )
  }

  private func request<Router: ApiRouter>(_ router: Router, parameters: RequestQuery) async throws -> NetworkResponse {
    do {
      return try await networkManager.request(router, parameters: parameters)
    } catch let error as NetworkError {
      Self.logger.error("❌ [CommunityAPI] transport failed error=\(String(describing: error), privacy: .public)")
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [CommunityAPI] unexpected failure error=\(String(describing: error), privacy: .public)")
      throw CommunityServiceError.transport
    }
  }

  private func requestWithBody<Router: ApiRouter, Body: Encodable>(
    _ router: Router,
    body: Body,
    parameters: RequestQuery
  ) async throws -> NetworkResponse {
    do {
      return try await networkManager.request(router, body: body, parameters: parameters)
    } catch let error as NetworkError {
      Self.logger.error("❌ [CommunityAPI] transport failed error=\(String(describing: error), privacy: .public)")
      throw mappedNetworkError(error)
    } catch {
      Self.logger.error("❌ [CommunityAPI] unexpected failure error=\(String(describing: error), privacy: .public)")
      throw CommunityServiceError.transport
    }
  }

  private func decode<DTO: Decodable>(_ type: DTO.Type, from response: NetworkResponse) throws -> DTO {
    switch response.statusCode {
    case 200 ..< 300:
      do {
        return try decoder.decode(type, from: response.data)
      } catch {
        Self.logger.error("❌ [CommunityAPI] decode failed error=\(String(describing: error), privacy: .public)")
        throw CommunityServiceError.invalidResponse
      }
    case 400:
      throw mappedServerMessageError(data: response.data)
    case 404:
      throw CommunityServiceError.notFound
    case 445:
      throw CommunityServiceError.permissionDenied
    default:
      throw CommunityServiceError.serverError
    }
  }

  private func validateEmptyResponse(_ response: NetworkResponse) throws {
    switch response.statusCode {
    case 200 ..< 300:
      return
    case 400:
      throw mappedServerMessageError(data: response.data)
    case 404:
      throw CommunityServiceError.notFound
    case 445:
      throw CommunityServiceError.permissionDenied
    default:
      throw CommunityServiceError.serverError
    }
  }

  private func pageQuery(
    nextCursor: String?,
    limit: Int,
    extra: [String: String] = [:]
  ) -> RequestQuery {
    var values = extra
    values["limit"] = String(limit)

    if let nextCursor, nextCursor.isEmpty == false {
      values["next"] = nextCursor
    }

    return RequestQuery(values)
  }

  private func mappedServerMessageError(data: Data) -> CommunityServiceError {
    guard
      let payload = try? decoder.decode(CommunityErrorResponseDTO.self, from: data),
      payload.message.isEmpty == false
    else {
      return .invalidRequest
    }

    return .invalidRequestMessage(payload.message)
  }

  private func mappedImageCompressionError(_ error: ImageCompressionError) -> CommunityServiceError {
    switch error {
    case .exceedsMaximumBytes:
      .invalidRequestMessage("동영상은 최대 5MB까지 업로드할 수 있습니다.")
    case .unsupportedFileExtension:
      .invalidRequestMessage("지원하지 않는 파일 형식입니다.")
    case .invalidImageData, .compressionFailed:
      .invalidRequest
    }
  }

  private func mappedNetworkError(_ error: NetworkError) -> CommunityServiceError {
    switch error {
    case .invalidRequest:
      .invalidRequest
    case .invalidResponse:
      .invalidResponse
    case .transport:
      .transport
    }
  }

  private func mappedCommentError(_ error: SharedCommentServiceError) -> CommunityServiceError {
    switch error {
    case .invalidRequest:
      .invalidRequest
    case .invalidResponse:
      .invalidResponse
    case .notFound:
      .notFound
    case .permissionDenied:
      .permissionDenied
    case .serverError:
      .serverError
    case .transport:
      .transport
    }
  }
}

private nonisolated struct CommunityErrorResponseDTO: Decodable, Sendable {
  let message: String
}

private extension Array where Element == MultipartFilePart {
  nonisolated var fileExtensionsDescription: String {
    map(\.fileName).fileExtensionsDescription
  }
}

private extension Array where Element == String {
  nonisolated var fileExtensionsDescription: String {
    map(\.lowercasedFileExtensionForLog).joined(separator: ",")
  }
}

private extension String {
  nonisolated var lowercasedFileExtensionForLog: String {
    guard let dotIndex = lastIndex(of: ".") else { return "(none)" }

    let fileExtension = self[index(after: dotIndex)...].lowercased()
    return fileExtension.isEmpty ? "(none)" : fileExtension
  }
}
