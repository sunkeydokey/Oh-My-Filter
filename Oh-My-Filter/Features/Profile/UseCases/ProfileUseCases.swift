import Foundation

nonisolated protocol ProfileUseCase: Sendable {
  func loadMyProfile() async throws -> MyProfile
  func updateProfile(draft: ProfileUpdateDraft) async throws -> MyProfile
  func uploadProfileImage(selections: [PhotoPickerUploadSelection]) async throws -> String?
}

nonisolated protocol OrderHistoryUseCase: Sendable {
  func loadOrders() async throws -> [OrderHistoryItem]
}

nonisolated struct LiveProfileUseCase: ProfileUseCase {
  private let service: any ProfileServicing
  private let imageUploadUseCase: any ImageUploadUseCase

  init(
    service: any ProfileServicing,
    imageUploadUseCase: any ImageUploadUseCase = LiveImageUploadUseCase()
  ) {
    self.service = service
    self.imageUploadUseCase = imageUploadUseCase
  }

  @MainActor
  init() {
    self.init(service: LiveProfileService())
  }

  func loadMyProfile() async throws -> MyProfile {
    try await service.loadMyProfile()
  }

  func updateProfile(draft: ProfileUpdateDraft) async throws -> MyProfile {
    try await service.updateProfile(
      request: ProfileUpdateRequest(
        nick: normalizedOptional(draft.nick),
        name: normalizedOptional(draft.name),
        introduction: normalizedOptional(draft.introduction),
        phoneNum: normalizedOptional(draft.phoneNumber),
        profileImage: draft.profileImage,
        hashTags: draft.hashTags
      )
    )
  }

  func uploadProfileImage(selections: [PhotoPickerUploadSelection]) async throws -> String? {
    let files = try imageUploadUseCase.multipartFiles(from: selections, preset: .profile)
    guard files.isEmpty == false else { return nil }
    return try await service.uploadProfileImage(multipartFiles: files)
  }

  private func normalizedOptional(_ value: String) -> String? {
    let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return normalized.isEmpty ? nil : normalized
  }
}

nonisolated struct LiveOrderHistoryUseCase: OrderHistoryUseCase {
  private let service: any OrderHistoryServicing

  init(service: any OrderHistoryServicing) {
    self.service = service
  }

  @MainActor
  init() {
    self.init(service: LiveOrderHistoryService())
  }

  func loadOrders() async throws -> [OrderHistoryItem] {
    try await service.loadOrders()
  }
}
