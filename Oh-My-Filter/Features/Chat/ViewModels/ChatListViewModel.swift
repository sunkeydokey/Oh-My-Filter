import Foundation
import Observation

@MainActor
@Observable
final class ChatListViewModel {
  private(set) var state = ChatListState()

  private let service: any ChatServicing
  private let store: any ChatLocalStoring
  private var searchTask: Task<Void, Never>?
  private var pendingRoomID: String?
  private var autoRefreshTask: Task<Void, Never>?

  init(
    service: any ChatServicing,
    store: any ChatLocalStoring
  ) {
    self.service = service
    self.store = store
  }

  func send(_ action: ChatListAction) async {
    switch action {
    case .task:
      await loadRooms()
    case .refresh:
      await refetchRooms(silent: false)
      restartAutoRefresh()
    case .autoRefresh:
      await refetchRooms(silent: true)
    case .disappeared:
      autoRefreshTask?.cancel()
      autoRefreshTask = nil
    case .viewAppeared:
      guard state.currentUserID.isEmpty == false else { return }
      restartAutoRefresh()
    case let .searchChanged(searchText):
      state.searchText = searchText
      debounceSearch(for: searchText)
    case let .searchResultTapped(user):
      await createRoom(with: user)
    case let .openRoom(roomID):
      await openRoom(roomID: roomID)
    case .selectedRoomCleared:
      state.selectedRoom = nil
    case let .filterChanged(filter):
      state.selectedFilter = filter
    }
  }

  private func loadRooms() async {
    state.errorMessage = nil
    state.rooms = (try? store.fetchRooms()) ?? []
    state.isLoading = true

    do {
      async let userID = service.loadCurrentUserID()
      async let rooms = service.loadRooms()

      let currentUserID = try await userID
      let remoteRooms = try await rooms.map { room in
        ChatRoom(
          id: room.id,
          updatedAt: room.updatedAt,
          participants: room.participants,
          lastMessage: room.lastMessage,
          lastSeenAt: try store.lastSeenAt(roomID: room.id)
        )
      }
      try store.upsertRooms(remoteRooms)

      state.currentUserID = currentUserID
      state.rooms = try store.fetchRooms()
      selectPendingRoomIfAvailable()
      state.isLoading = false
      restartAutoRefresh()
    } catch is CancellationError {
      state.isLoading = false
    } catch {
      state.isLoading = false
      state.errorMessage = Self.message(for: error)
    }
  }

  private func debounceSearch(for searchText: String) {
    searchTask?.cancel()
    state.searchErrorMessage = nil

    let nick = normalizedSearchText(searchText)
    guard nick.isEmpty == false else {
      state.searchResults = []
      state.isSearchingUsers = false
      return
    }

    searchTask = Task { [weak self] in
      do {
        try await Task.sleep(for: .seconds(1))
        await self?.searchUsers(nick: nick)
      } catch is CancellationError {
      } catch {
        self?.handleSearchFailure(error)
      }
    }
  }

  private func searchUsers(nick: String) async {
    guard normalizedSearchText(state.searchText) == nick else { return }

    state.isSearchingUsers = true
    state.searchErrorMessage = nil

    do {
      let users = try await service.searchUsers(nick: nick)
      guard normalizedSearchText(state.searchText) == nick else { return }
      state.searchResults = users
      state.isSearchingUsers = false
    } catch is CancellationError {
      state.isSearchingUsers = false
    } catch {
      handleSearchFailure(error)
    }
  }

  private func createRoom(with user: ChatUser) async {
    guard state.creatingRoomUserID == nil else { return }

    state.creatingRoomUserID = user.id
    state.searchErrorMessage = nil

    do {
      let room = try await service.createRoom(opponentID: user.id)
      try store.upsertRoom(room)
      state.rooms = try store.fetchRooms()
      state.selectedRoom = room
      state.creatingRoomUserID = nil
    } catch is CancellationError {
      state.creatingRoomUserID = nil
    } catch {
      state.creatingRoomUserID = nil
      state.searchErrorMessage = Self.message(for: error)
    }
  }

  private func openRoom(roomID: String) async {
    pendingRoomID = roomID
    if selectPendingRoomIfAvailable() {
      return
    }

    await loadRooms()
  }

  @discardableResult
  private func selectPendingRoomIfAvailable() -> Bool {
    guard let pendingRoomID else { return false }
    guard let room = state.rooms.first(where: { $0.id == pendingRoomID }) else {
      return false
    }

    state.selectedRoom = room
    self.pendingRoomID = nil
    return true
  }

  private func refetchRooms(silent: Bool) async {
    guard state.currentUserID.isEmpty == false else { return }

    do {
      let remoteRooms = try await service.loadRooms().map { room in
        ChatRoom(
          id: room.id,
          updatedAt: room.updatedAt,
          participants: room.participants,
          lastMessage: room.lastMessage,
          lastSeenAt: try store.lastSeenAt(roomID: room.id)
        )
      }
      try store.upsertRooms(remoteRooms)
      state.rooms = try store.fetchRooms()
      selectPendingRoomIfAvailable()
    } catch is CancellationError {
    } catch {
      if silent == false {
        state.errorMessage = Self.message(for: error)
      }
    }
  }

  private func restartAutoRefresh() {
    autoRefreshTask?.cancel()
    autoRefreshTask = Task { [weak self] in
      while true {
        do {
          try await Task.sleep(for: .seconds(15))
        } catch {
          return
        }
        await self?.send(.autoRefresh)
      }
    }
  }

  private func handleSearchFailure(_ error: Error) {
    state.isSearchingUsers = false
    state.searchResults = []
    state.searchErrorMessage = Self.message(for: error)
  }

  private func normalizedSearchText(_ searchText: String) -> String {
    searchText.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private static func message(for error: Error) -> String {
    if let error = error as? ChatServiceError {
      switch error {
      case .transport:
        return "네트워크 상태를 확인한 뒤 다시 시도해 주세요."
      case .serverError, .decoding, .emptyCurrentUser:
        return "잠시 후 다시 시도해 주세요."
      }
    }
    return "잠시 후 다시 시도해 주세요."
  }
}
