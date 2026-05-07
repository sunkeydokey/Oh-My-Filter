import SwiftUI

struct ProfileView: View {
  @State private var viewModel: ProfileViewModel
  let onEdit: () -> Void

  init(
    viewModel: ProfileViewModel? = nil,
    onEdit: @escaping () -> Void = {}
  ) {
    _viewModel = State(initialValue: viewModel ?? ProfileViewModel())
    self.onEdit = onEdit
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        profileCard
        ProfileSectionTitle(title: "기본 정보")
        infoCard

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
    .navigationTitle("Profile")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          onEdit()
        } label: {
          Label("수정", systemImage: "pencil")
        }
      }
    }
    .task {
      await viewModel.send(.task)
    }
    .refreshable {
      await viewModel.send(.retry)
    }
  }

  private var profileCard: some View {
    VStack(spacing: 12) {
      ProfileAvatarView(profile: viewModel.state.profile, size: 86)
      Text("\(viewModel.state.profile?.displayName ?? "MY") 님")
        .font(TypographyToken.pretendardTitle1.font.weight(.heavy))
        .foregroundStyle(ColorToken.grayScale0.color)

      Text(viewModel.state.profile?.introduction ?? "자연광 필터와 따뜻한 톤을 즐겨 쓰는 사용자")
        .font(TypographyToken.pretendardCaption1.font)
        .foregroundStyle(ColorToken.grayScale60.color)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)

      HStack(spacing: 8) {
        metric(value: "0", label: "저장 필터")
        metric(value: "\(viewModel.state.orderCount)", label: "주문")
      }
    }
    .frame(maxWidth: .infinity)
    .profileGlassCard()
    .redacted(reason: viewModel.state.isLoading && viewModel.state.profile == nil ? .placeholder : [])
  }

  private var infoCard: some View {
    VStack(spacing: 4) {
      ProfileInfoRow(icon: "envelope", label: "이메일", value: viewModel.state.profile?.email ?? "-")
      ProfileInfoRow(icon: "phone", label: "연락처", value: viewModel.state.profile?.phoneNumber ?? "-")
      if let tags = viewModel.state.profile?.hashTags, tags.isEmpty == false {
        ProfileInfoRow(icon: "sparkles", label: "필터 취향", value: tags.joined(separator: " "))
      }
    }
    .padding(8)
    .profileGlassCard()
  }

  private func metric(value: String, label: String) -> some View {
    VStack(spacing: 3) {
      Text(value)
        .font(TypographyToken.pretendardBody1.font.weight(.heavy))
        .foregroundStyle(ColorToken.grayScale0.color)
      Text(label)
        .font(TypographyToken.pretendardCaption2.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale60.color)
    }
    .padding(10)
    .frame(maxWidth: .infinity)
    .background(ColorToken.grayScale90.color.opacity(0.44), in: .rect(cornerRadius: 18, style: .continuous))
  }
}
