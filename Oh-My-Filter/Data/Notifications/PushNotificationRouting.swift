import Foundation
import Observation

extension Notification.Name {
  static let pushNotificationReceived = Notification.Name("com.oh-my-filter.pushNotificationReceived")
}

nonisolated enum PushNotificationRouteParser {
  static func route(from userInfo: [AnyHashable: Any]) -> AppAuthenticatedRoute? {
    guard let roomID = roomID(from: userInfo) else { return nil }

    if let notificationType = notificationType(from: userInfo),
       notificationType.localizedStandardContains("chat") == false {
      return nil
    }

    return .chatRoom(roomID: roomID)
  }

  private static func roomID(from userInfo: [AnyHashable: Any]) -> String? {
    for key in ["room_id", "roomId", "roomID", "chatRoomID", "chatRoomId"] {
      if let value = stringValue(for: key, in: userInfo), value.isEmpty == false {
        return value
      }
    }

    return nil
  }

  private static func notificationType(from userInfo: [AnyHashable: Any]) -> String? {
    for key in ["type", "notification_type", "notificationType"] {
      if let value = stringValue(for: key, in: userInfo), value.isEmpty == false {
        return value
      }
    }

    return nil
  }

  private static func stringValue(for key: String, in userInfo: [AnyHashable: Any]) -> String? {
    guard let value = userInfo[key] ?? userInfo[AnyHashable(key)] else {
      return nil
    }

    if let string = value as? String {
      return string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    if let number = value as? NSNumber {
      return number.stringValue
    }

    return nil
  }
}

@MainActor
@Observable
final class PushNotificationRoutingStore {
  static let shared = PushNotificationRoutingStore()

  private(set) var pendingRoute: AppAuthenticatedRoute?

  init() {}

  func receive(userInfo: [AnyHashable: Any]) {
    guard let route = PushNotificationRouteParser.route(from: userInfo) else { return }
    pendingRoute = route
  }

  func consumePendingRoute() -> AppAuthenticatedRoute? {
    let route = pendingRoute
    pendingRoute = nil
    return route
  }
}
