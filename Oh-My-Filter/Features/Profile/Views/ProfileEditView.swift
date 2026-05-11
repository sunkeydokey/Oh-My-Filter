import PhotosUI
import SwiftUI

struct ProfileEditView: View {
  @State private var viewModel: ProfileEditViewModel
  @Environment(\.dismiss) private var dismiss

  init(viewModel: ProfileEditViewModel? = nil) {
    _viewModel = State(initialValue: viewModel ?? ProfileEditViewModel())
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        CustomStackNavigationHeader(title: "프로필 편집", onBack: { dismiss() }) {
          Button("저장") {
            viewModel.send(.saveTapped)
          }
          .font(TypographyToken.pretendardBody2.font.weight(.bold))
          .foregroundStyle(viewModel.state.canSave ? ColorToken.mainAccent.color : ColorToken.grayScale60.color)
          .disabled(viewModel.state.canSave == false)
        }

        avatarCard
        ProfileSectionTitle(title: "정보 수정")
        formCard
        ProfileSectionTitle(title: "필터 취향")
        preferenceCard

        if let message = viewModel.state.message {
          Text(message)
            .font(TypographyToken.pretendardCaption1.font)
            .foregroundStyle(ColorToken.grayScale60.color)
            .frame(maxWidth: .infinity)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 18)
    }
    .scrollIndicators(.hidden)
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
    .toolbar(.hidden, for: .navigationBar)
    .swipeBackEnabled()
    .safeAreaInset(edge: .bottom) {
      Button {
        viewModel.send(.saveTapped)
      } label: {
        HStack(spacing: 8) {
          if viewModel.state.isSaving {
            ProgressView()
              .tint(ColorToken.grayScale100.color)
          }
          Text("변경사항 저장")
            .font(TypographyToken.pretendardBody2.font.weight(.heavy))
        }
        .foregroundStyle(ColorToken.grayScale100.color)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(viewModel.state.canSave ? ColorToken.mainAccent.color : ColorToken.grayScale90.color, in: .rect(cornerRadius: 22, style: .continuous))
        .buttonHitArea(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(ColorToken.grayScale100.color)
      }
      .buttonStyle(.plain)
      .disabled(viewModel.state.canSave == false)
    }
    .task {
      if let task = viewModel.send(.task) {
        await task.value
      }
    }
    .onChange(of: viewModel.state.originalProfile) { _, newValue in
      guard newValue != nil, viewModel.state.isSaving == false else { return }
    }
    .onAppear {
      viewModel.onSaveSucceeded = { _ in
        dismiss()
      }
    }
  }

  private var avatarCard: some View {
    HStack(spacing: 12) {
      ProfileAvatarView(profile: viewModel.state.originalProfile, size: 66)

      VStack(alignment: .leading, spacing: 8) {
        Text("프로필 이미지")
          .font(TypographyToken.pretendardBody2.font.weight(.heavy))
          .foregroundStyle(ColorToken.grayScale0.color)
        Text("사진을 변경하면 모든 화면에 반영돼요.")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale60.color)
        PhotoPickerUploadView(
          preset: .profile,
          selections: Binding(
            get: { viewModel.state.selectedImages },
            set: { viewModel.send(.imageSelectionsChanged($0)) }
          )
        )
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .profileGlassCard()
  }

  private var formCard: some View {
    VStack(spacing: 6) {
      ProfileFormField(label: "닉네임", placeholder: "닉네임", text: draftBinding(\.nick, action: ProfileEditAction.nickChanged))
      ProfileFormField(label: "이름", placeholder: "이름", text: draftBinding(\.name, action: ProfileEditAction.nameChanged))
      ProfileFormField(label: "소개", placeholder: "프로필 소개", text: draftBinding(\.introduction, action: ProfileEditAction.introductionChanged))
      ProfileFormField(label: "연락처", placeholder: "010-1234-5678", text: draftBinding(\.phoneNumber, action: ProfileEditAction.phoneNumberChanged))
    }
    .padding(8)
    .profileGlassCard()
    .redacted(reason: viewModel.state.isLoading && viewModel.state.draft == nil ? .placeholder : [])
  }

  private var preferenceCard: some View {
    ProfileFormField(
      label: "해시태그",
      placeholder: "#맑음, #따뜻함",
      text: Binding(
        get: { viewModel.state.hashTagsText },
        set: { viewModel.send(.hashTagsChanged($0)) }
      )
    )
    .profileGlassCard()
  }

  private func draftBinding(
    _ keyPath: WritableKeyPath<ProfileUpdateDraft, String>,
    action: @escaping (String) -> ProfileEditAction
  ) -> Binding<String> {
    Binding(
      get: { viewModel.state.draft?[keyPath: keyPath] ?? "" },
      set: { viewModel.send(action($0)) }
    )
  }
}
