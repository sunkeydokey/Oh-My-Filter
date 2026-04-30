import Foundation

enum ChatRoomFilter: Hashable, Sendable {
  case all
  case unread
}

struct ChatListState: Equatable, Sendable {
  var rooms: [ChatRoom] = []
  var searchText = ""
  var searchResults: [ChatUser] = []
  var isSearchingUsers = false
  var creatingRoomUserID: String?
  var searchErrorMessage: String?
  var selectedRoom: ChatRoom?
  var selectedFilter: ChatRoomFilter = .all
  var isLoading = false
  var errorMessage: String?
  var currentUserID = ""

  var unreadCount: Int {
    rooms.filter(\.isUnread).count
  }

  var visibleRooms: [ChatRoom] {
    rooms.filter { room in
      let matchesFilter = selectedFilter == .all || room.isUnread
      let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
      guard query.isEmpty == false else { return matchesFilter }

      let participantText = room.participants.map(\.nick).joined(separator: " ")
      let messageText = room.lastMessage?.content ?? ""
      return matchesFilter
        && (participantText.localizedStandardContains(query) || messageText.localizedStandardContains(query))
    }
  }
}
