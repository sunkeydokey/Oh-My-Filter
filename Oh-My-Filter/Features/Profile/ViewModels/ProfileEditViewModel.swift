import Foundation
import Observation

nonisolated enum ProfileEditAction: Equatable, Sendable {
  case task
  case nickChanged(String)
  case nameChanged(String)
  case introductionChanged(String)
  case phoneNumberChanged(String)
  case hashTagsChanged(String)
  case imageSelectionsChanged([PhotoPickerUploadSelection])
  case saveTapped
}

nonisolated struct ProfileEditState: Equatable, Sendable {
  var originalProfile: MyProfile?
  var draft: ProfileUpdateDraft?
  var hashTagsText = ""
  var selectedImages: [PhotoPickerUploadSelection] = []
  var isLoading = false
  var isSaving = false
  var message: String?

  var canSave: Bool {
    guard let draft else { return false }
    return draft.nick.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && isSaving == false
  }
}

@MainActor
@Observable
final class ProfileEditViewModel {
  var state = ProfileEditState()
  var onSaveSucceeded: @MainActor (MyProfile) -> Void

  private let useCase: any ProfileUseCase

  init(
    useCase: (any ProfileUseCase)? = nil,
    onSaveSucceeded: @escaping @MainActor (MyProfile) -> Void = { _ in }
  ) {
    self.useCase = useCase ?? LiveProfileUseCase()
    self.onSaveSucceeded = onSaveSucceeded
  }

  @discardableResult
  func send(_ action: ProfileEditAction) -> Task<Void, Never>? {
    switch action {
    case .task:
      return load()
    case let .nickChanged(value):
      state.draft?.nick = value
      state.message = nil
      return nil
    case let .nameChanged(value):
      state.draft?.name = value
      state.message = nil
      return nil
    case let .introductionChanged(value):
      state.draft?.introduction = value
      state.message = nil
      return nil
    case let .phoneNumberChanged(value):
      state.draft?.phoneNumber = value
      state.message = nil
      return nil
    case let .hashTagsChanged(value):
      state.hashTagsText = value
      state.draft?.hashTags = value
        .split(separator: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { $0.isEmpty == false }
      state.message = nil
      return nil
    case let .imageSelectionsChanged(selections):
      state.selectedImages = selections
      state.message = nil
      return nil
    case .saveTapped:
      return save()
    }
  }

  private func load() -> Task<Void, Never> {
    state.isLoading = true
    state.message = nil

    return Task {
      do {
        let profile = try await useCase.loadMyProfile()
        state.originalProfile = profile
        state.draft = ProfileUpdateDraft(profile: profile)
        state.hashTagsText = profile.hashTags.joined(separator: ", ")
      } catch is CancellationError {
        return
      } catch {
        state.message = fallbackMessage(for: error)
      }
      state.isLoading = false
    }
  }

  private func save() -> Task<Void, Never>? {
    guard var draft = state.draft, state.canSave else {
      state.message = "닉네임을 입력해 주세요."
      return nil
    }

    state.isSaving = true
    state.message = nil
    let selections = state.selectedImages

    return Task {
      do {
        if selections.isEmpty == false {
          draft.profileImage = try await useCase.uploadProfileImage(selections: selections)
        }
        let profile = try await useCase.updateProfile(draft: draft)
        state.originalProfile = profile
        state.draft = ProfileUpdateDraft(profile: profile)
        state.hashTagsText = profile.hashTags.joined(separator: ", ")
        state.selectedImages = []
        state.isSaving = false
        onSaveSucceeded(profile)
      } catch let error as ProfileServiceError {
        state.message = error.errorDescription
        state.isSaving = false
      } catch {
        state.message = fallbackMessage(for: error)
        state.isSaving = false
      }
    }
  }

  private func fallbackMessage(for error: Error) -> String {
    if let error = error as? LocalizedError, let description = error.errorDescription {
      return description
    }
    return "프로필을 저장할 수 없습니다. 잠시 후 다시 시도해 주세요."
  }
}
