import SwiftUI

struct CommunityHeaderView: View {
  let onCreatePost: () -> Void

  var body: some View {
    HStack {
      Text("Community")
        .font(.custom(TypographyToken.mulgyeolTitle1.fontName, size: 24, relativeTo: .title2))
        .foregroundStyle(ColorToken.grayScale0.color)

      Spacer()

      Button(action: onCreatePost) {
        Image(systemName: "square.and.pencil")
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(ColorToken.grayScale0.color)
          .frame(width: 38, height: 38)
          .background(ColorToken.brandBlackSprout.color, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("게시글 작성")
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct CommunitySearchBarView: View {
  let searchText: String
  let onSearchTextChanged: (String) -> Void
  let onSubmitSearch: () -> Void
  let onClearSearch: () -> Void

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(ColorToken.grayScale60.color)

      TextField("제목으로 검색", text: Binding(
        get: { searchText },
        set: onSearchTextChanged
      ))
      .font(TypographyToken.pretendardBody2.font)
      .foregroundStyle(ColorToken.grayScale0.color)
      .submitLabel(.search)
      .onSubmit(onSubmitSearch)

      if searchText.isEmpty == false {
        Button(action: onClearSearch) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(ColorToken.grayScale60.color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("검색어 지우기")
      }
    }
    .frame(height: 48)
    .padding(.horizontal, 16)
    .background(ColorToken.brandBlackSprout.color, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
  }
}

struct CommunityTabBarView: View {
  let selectedTab: CommunityTab
  let onTabSelected: (CommunityTab) -> Void

  var body: some View {
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        ForEach(CommunityTab.allCases, id: \.self) { tab in
          Button {
            onTabSelected(tab)
          } label: {
            Text(tab.title)
              .font(TypographyToken.pretendardCaption1.font)
              .foregroundStyle(selectedTab == tab ? ColorToken.grayScale100.color : ColorToken.grayScale0.color)
              .padding(.horizontal, 16)
              .frame(height: 34)
              .background(tabFill(for: tab), in: Capsule())
              .buttonHitArea(Capsule())
          }
          .buttonStyle(.plain)
        }
      }
    }
    .scrollIndicators(.hidden)
  }

  private func tabFill(for tab: CommunityTab) -> Color {
    selectedTab == tab
      ? ColorToken.mainAccent.color
      : ColorToken.brandBlackSprout.color
  }
}
