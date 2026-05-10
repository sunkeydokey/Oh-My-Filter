import SwiftData
import SwiftUI

struct ChatListView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var viewModel: ChatListViewModel?
  @Binding private var pendingRoomID: String?

  init(pendingRoomID: Binding<String?> = .constant(nil)) {
    _pendingRoomID = pendingRoomID
  }

  var body: some View {
    Group {
      if let viewModel {
        ChatListContentView(viewModel: viewModel)
      } else {
        ProgressView()
          .tint(ColorToken.mainAccent.color)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .background(ColorToken.brandBlackSprout.color.ignoresSafeArea())
    .task {
      if viewModel == nil {
        viewModel = ChatListViewModel(
          service: LiveChatService(),
          store: SwiftDataChatStore(context: modelContext)
        )
      }
      await viewModel?.send(.task)
    }
    .task(id: pendingRoomID) {
      guard let pendingRoomID else { return }
      if viewModel == nil {
        viewModel = ChatListViewModel(
          service: LiveChatService(),
          store: SwiftDataChatStore(context: modelContext)
        )
      }
      await viewModel?.send(.openRoom(pendingRoomID))
      if viewModel?.state.selectedRoom?.id == pendingRoomID {
        self.pendingRoomID = nil
      }
    }
  }
}

private struct ChatListContentView: View {
  @Bindable var viewModel: ChatListViewModel
  @Environment(\.modelContext) private var modelContext
  @FocusState private var isSearchFocused: Bool

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        header
        searchBar
        filterChips

        Text("최근")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .padding(.top, 2)

        LazyVStack(spacing: 12) {
          ForEach(viewModel.state.visibleRooms) { room in
            NavigationLink {
              ChatView(
                room: room,
                currentUserID: viewModel.state.currentUserID,
                service: LiveChatService(),
                store: SwiftDataChatStore(context: modelContext),
                socketManager: SocketIOChatSocketManager()
              )
            } label: {
              ChatRoomRowView(
                room: room,
                currentUserID: viewModel.state.currentUserID
              )
            }
            .buttonStyle(.plain)
          }
        }

        searchResults
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 18)
    }
    .scrollDismissesKeyboard(.interactively)
    .onTapGesture {
      isSearchFocused = false
    }
    .refreshable {
      await viewModel.send(.refresh)
    }
    .navigationDestination(
      isPresented: Binding(
        get: { viewModel.state.selectedRoom != nil },
        set: { isPresented in
          guard isPresented == false else { return }
          Task { await viewModel.send(.selectedRoomCleared) }
        }
      )
    ) {
      if let room = viewModel.state.selectedRoom {
        ChatView(
          room: room,
          currentUserID: viewModel.state.currentUserID,
          service: LiveChatService(),
          store: SwiftDataChatStore(context: modelContext),
          socketManager: SocketIOChatSocketManager()
        )
      }
    }
    .background(ColorToken.brandBlackSprout.color)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .navigationBar)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("채팅")
        .font(TypographyToken.mulgyeolTitle1.font)
        .foregroundStyle(ColorToken.grayScale0.color)

      Text("읽지 않은 대화 \(viewModel.state.unreadCount)개")
        .font(TypographyToken.pretendardBody3.font)
        .foregroundStyle(ColorToken.grayScale45.color)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var searchBar: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(ColorToken.grayScale60.color)

      TextField("대화 상대를 찾아보세요", text: Binding(
        get: { viewModel.state.searchText },
        set: { text in Task { await viewModel.send(.searchChanged(text)) } }
      ))
      .textInputAutocapitalization(.never)
      .autocorrectionDisabled()
      .focused($isSearchFocused)
      .font(TypographyToken.pretendardBody3.font)
      .foregroundStyle(ColorToken.grayScale0.color)
    }
    .padding(.horizontal, 16)
    .frame(height: 48)
    .background(ColorToken.grayScale100.color, in: .rect(cornerRadius: 18))
    .overlay {
      RoundedRectangle(cornerRadius: 18)
        .stroke(ColorToken.grayScale90.color.opacity(0.5), lineWidth: 1)
    }
  }

  private var filterChips: some View {
    HStack(spacing: 8) {
      ChatFilterChip(
        title: "전체",
        isSelected: viewModel.state.selectedFilter == .all
      ) {
        Task { await viewModel.send(.filterChanged(.all)) }
      }

      ChatFilterChip(
        title: "읽지 않음",
        isSelected: viewModel.state.selectedFilter == .unread
      ) {
        Task { await viewModel.send(.filterChanged(.unread)) }
      }
    }
  }

  @ViewBuilder
  private var searchResults: some View {
    if viewModel.state.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
      VStack(alignment: .leading, spacing: 12) {
        Text("사용자 검색")
          .font(TypographyToken.pretendardCaption1.font)
          .foregroundStyle(ColorToken.grayScale45.color)
          .padding(.top, 6)

        if viewModel.state.isSearchingUsers {
          ProgressView()
            .tint(ColorToken.mainAccent.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else if let message = viewModel.state.searchErrorMessage {
          Text(message)
            .font(TypographyToken.pretendardBody3.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        } else if viewModel.state.searchResults.isEmpty {
          Text("검색 결과가 없어요")
            .font(TypographyToken.pretendardBody3.font)
            .foregroundStyle(ColorToken.grayScale45.color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        } else {
          LazyVStack(spacing: 12) {
            ForEach(viewModel.state.searchResults) { user in
              Button {
                isSearchFocused = false
                Task { await viewModel.send(.searchResultTapped(user)) }
              } label: {
                ChatUserSearchRowView(
                  user: user,
                  isLoading: viewModel.state.creatingRoomUserID == user.id
                )
              }
              .buttonStyle(.plain)
              .disabled(viewModel.state.creatingRoomUserID != nil)
            }
          }
        }
      }
    }
  }
}

private struct ChatFilterChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(TypographyToken.pretendardCaption1.font.weight(isSelected ? .semibold : .medium))
        .foregroundStyle(isSelected ? ColorToken.brandBlackSprout.color : ColorToken.grayScale15.color)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isSelected ? ColorToken.grayScale0.color : ColorToken.grayScale100.color, in: .capsule)
        .overlay {
          Capsule()
            .stroke(ColorToken.grayScale90.color.opacity(isSelected ? 0 : 0.5), lineWidth: 1)
        }
        .buttonHitArea(Capsule())
    }
    .buttonStyle(.plain)
  }
}

private struct ChatRoomRowView: View {
  let room: ChatRoom
  let currentUserID: String

  private var displayUser: ChatUser? {
    room.participants.first { $0.id != currentUserID } ?? room.participants.first
  }

  var body: some View {
    HStack(spacing: 16) {
      ChatAvatarView(text: displayUser?.nick ?? "채팅", size: 56)

      VStack(alignment: .leading, spacing: 4) {
        Text(displayUser?.nick ?? "채팅")
          .font(TypographyToken.mulgyeolBody1.font)
          .foregroundStyle(ColorToken.grayScale0.color)
          .lineLimit(1)

        Text(room.lastMessage?.content ?? "새 대화를 시작해 보세요")
          .font(TypographyToken.pretendardBody3.font.weight(.medium))
          .foregroundStyle(ColorToken.grayScale45.color)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      VStack(spacing: 8) {
        Text(chatListDate(room.updatedAt))
          .font(TypographyToken.pretendardCaption2.font.weight(.semibold))
          .foregroundStyle(ColorToken.grayScale45.color)
          .lineLimit(1)

        if room.isUnread {
          Circle()
            .fill(ColorToken.mainAccent.color)
            .frame(width: 8, height: 8)
            .frame(width: 24, height: 24)
            .background(ColorToken.grayScale100.color, in: .rect(cornerRadius: 12))
            .overlay {
              RoundedRectangle(cornerRadius: 12)
                .stroke(ColorToken.mainAccent.color, lineWidth: 1)
            }
        }
      }
      .frame(width: 58)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(height: 84)
    .background(room.isUnread ? Color(red: 0.09, green: 0.09, blue: 0.11) : ColorToken.grayScale100.color, in: .rect(cornerRadius: 24))
    .overlay {
      RoundedRectangle(cornerRadius: 24)
        .stroke(ColorToken.grayScale90.color.opacity(0.5), lineWidth: 1)
    }
  }

  private func chatListDate(_ date: Date) -> String {
    if Calendar.current.isDateInToday(date) {
      return date.formatted(date: .omitted, time: .shortened)
    }
    return date.formatted(date: .numeric, time: .omitted)
  }
}

private struct ChatUserSearchRowView: View {
  let user: ChatUser
  let isLoading: Bool

  var body: some View {
    HStack(spacing: 16) {
      ChatAvatarView(text: user.nick, size: 48)

      VStack(alignment: .leading, spacing: 4) {
        Text(user.nick)
          .font(TypographyToken.mulgyeolBody1.font)
          .foregroundStyle(ColorToken.grayScale0.color)
          .lineLimit(1)

        Text(user.introduction ?? user.name ?? "새 대화를 시작해 보세요")
          .font(TypographyToken.pretendardBody3.font.weight(.medium))
          .foregroundStyle(ColorToken.grayScale45.color)
          .lineLimit(1)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if isLoading {
        ProgressView()
          .tint(ColorToken.mainAccent.color)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(height: 76)
    .background(ColorToken.grayScale100.color, in: .rect(cornerRadius: 24))
    .overlay {
      RoundedRectangle(cornerRadius: 24)
        .stroke(ColorToken.grayScale90.color.opacity(0.5), lineWidth: 1)
    }
  }
}

struct ChatAvatarView: View {
  let text: String
  let size: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .fill(LinearGradient(
          colors: [Color(red: 0.19, green: 0.32, blue: 0.30), Color(red: 0.28, green: 0.24, blue: 0.35)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ))
      Text(String(text.prefix(1)))
        .font(TypographyToken.pretendardBody2.font.weight(.bold))
        .foregroundStyle(ColorToken.grayScale0.color)
    }
    .frame(width: size, height: size)
    .overlay {
      Circle()
        .stroke(ColorToken.grayScale60.color.opacity(0.5), lineWidth: 1)
    }
  }
}
