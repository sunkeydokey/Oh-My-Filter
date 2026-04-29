import Foundation

enum ChatListAction: Equatable, Sendable {
  case task
  case refresh
  case searchChanged(String)
  case searchResultTapped(ChatUser)
  case selectedRoomCleared
  case filterChanged(ChatRoomFilter)
}
