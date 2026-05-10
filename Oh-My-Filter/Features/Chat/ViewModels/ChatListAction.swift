import Foundation

enum ChatListAction: Equatable, Sendable {
  case task
  case refresh
  case autoRefresh
  case disappeared
  case viewAppeared
  case searchChanged(String)
  case searchResultTapped(ChatUser)
  case openRoom(String)
  case selectedRoomCleared
  case filterChanged(ChatRoomFilter)
}
