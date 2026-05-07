import SwiftUI

struct MyView: View {
  @State private var viewModel: MyViewModel
  let navigate: (ProfileRoute) -> Void
  let onLogout: () -> Void

  init(
    viewModel: MyViewModel? = nil,
    navigate: @escaping (ProfileRoute) -> Void = { _ in },
    onLogout: @escaping () -> Void = {}
  ) {
    _viewModel = State(initialValue: viewModel ?? MyViewModel())
    self.navigate = navigate
    self.onLogout = onLogout
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        profileSummary
        ProfileSectionTitle(title: "계정")
        actionsCard

        if let message = viewModel.state.message {
          retryView(message)
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 18)
    }
    .scrollIndicators(.hidden)
    .background(ColorToken.grayScale100.color.ignoresSafeArea())
    .navigationTitle("MY")
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          navigate(.edit)
        } label: {
          Image(systemName: "gearshape")
        }
        .accessibilityLabel("프로필 편집")
      }
    }
    .task {
      await viewModel.send(.task)
    }
    .refreshable {
      await viewModel.send(.retry)
    }
  }

  private var profileSummary: some View {
    HStack(spacing: 12) {
      ProfileAvatarView(profile: viewModel.state.profile, size: 64)

      VStack(alignment: .leading, spacing: 6) {
        Text("\(viewModel.state.profile?.displayName ?? "MY") 님")
          .font(TypographyToken.pretendardBody1.font.weight(.heavy))
          .foregroundStyle(ColorToken.grayScale0.color)
        Text(viewModel.state.profile?.introduction ?? "자기 소개를 넣어줘.")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale60.color)
          .lineLimit(2)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .profileGlassCard()
    .redacted(reason: viewModel.state.isLoading && viewModel.state.profile == nil ? .placeholder : [])
  }

  private var actionsCard: some View {
    VStack(spacing: 4) {
      ProfileActionRow(
        icon: "person",
        title: "프로필 보기",
        subtitle: "닉네임과 프로필 정보를 관리해요"
      ) {
        navigate(.profile)
      }

      ProfileActionRow(
        icon: "receipt",
        title: "주문 내역",
        subtitle: "최근 주문과 결제 결과를 확인해요",
        tint: Color(red: 0.95, green: 0.64, blue: 0.54)
      ) {
        navigate(.receipts)
      }

      ProfileActionRow(
        icon: "rectangle.portrait.and.arrow.right",
        title: "로그아웃",
        subtitle: "현재 기기에서 계정을 종료해요",
        tint: Color(red: 0.95, green: 0.64, blue: 0.54),
        action: onLogout
      )
    }
    .padding(8)
    .profileGlassCard()
  }

  private func retryView(_ message: String) -> some View {
    VStack(spacing: 10) {
      Text(message)
        .font(TypographyToken.pretendardCaption1.font)
        .foregroundStyle(ColorToken.grayScale60.color)
      Button("다시 시도") {
        Task {
          await viewModel.send(.retry)
        }
      }
      .font(TypographyToken.pretendardBody3.font.weight(.bold))
      .foregroundStyle(ColorToken.mainAccent.color)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 8)
  }
}
