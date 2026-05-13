import SwiftUI

struct ReceiptView: View {
  @State private var viewModel: ReceiptViewModel
  @Environment(\.dismiss) private var dismiss
  private let navigate: (ProfileRoute) -> Void

  init(
    viewModel: ReceiptViewModel? = nil,
    navigate: @escaping (ProfileRoute) -> Void = { _ in }
  ) {
    _viewModel = State(initialValue: viewModel ?? ReceiptViewModel())
    self.navigate = navigate
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        CustomStackNavigationHeader(title: "주문 내역", onBack: { dismiss() }) {
          Button {
            Task {
              await viewModel.send(.retry)
            }
          } label: {
            Image(systemName: "arrow.clockwise")
              .font(.system(size: 20, weight: .semibold))
              .foregroundStyle(ColorToken.grayScale45.color)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("주문 내역 새로고침")
        }

        summaryCard
        ProfileSectionTitle(title: "리스트")

        if viewModel.state.orders.isEmpty, viewModel.state.isLoading == false {
          emptyView
        } else {
          ForEach(viewModel.state.orders) { order in
            OrderHistoryCardView(order: order) {
              navigate(.playground(filter: order.filter))
            }
          }
        }

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
    .task {
      await viewModel.send(.task)
    }
    .refreshable {
      await viewModel.send(.retry)
    }
  }

  private var summaryCard: some View {
    HStack(spacing: 12) {
      Image(systemName: "receipt")
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(ColorToken.mainAccent.color)
        .frame(width: 48, height: 48)
        .background(ColorToken.mainAccent.color.opacity(0.16), in: .rect(cornerRadius: 18, style: .continuous))

      VStack(alignment: .leading, spacing: 4) {
        Text("최근 주문 \(viewModel.state.orders.count)건")
          .font(TypographyToken.pretendardBody1.font.weight(.heavy))
          .foregroundStyle(ColorToken.grayScale0.color)
        Text("결제 완료된 필터만 표시합니다.")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale60.color)
        Text("결제 완료")
          .font(TypographyToken.pretendardCaption1.font.weight(.heavy))
          .foregroundStyle(ColorToken.mainAccent.color)
          .padding(.horizontal, 9)
          .padding(.vertical, 6)
          .background(ColorToken.mainAccent.color.opacity(0.16), in: .capsule)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .profileGlassCard()
  }

  private var emptyView: some View {
    VStack(spacing: 10) {
      Image(systemName: "receipt")
        .font(.system(size: 28, weight: .semibold))
      Text("주문 내역이 없습니다.")
        .font(TypographyToken.pretendardBody2.font.weight(.bold))
    }
    .foregroundStyle(ColorToken.grayScale60.color)
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
    .profileGlassCard()
  }
}
