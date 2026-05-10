import Testing
@testable import Oh_My_Filter

struct PushNotificationRoutingTests {
  @Test("chat push payload with snake case room id routes to chat room")
  func chatPayloadRoutesToChatRoom() {
    let route = PushNotificationRouteParser.route(from: [
      "type": "chat",
      "room_id": "room-1",
    ])

    #expect(route == .chatRoom(roomID: "room-1"))
  }

  @Test("non-chat typed payload is ignored")
  func nonChatPayloadIsIgnored() {
    let route = PushNotificationRouteParser.route(from: [
      "type": "payment",
      "room_id": "room-1",
    ])

    #expect(route == nil)
  }

  @Test("payload without explicit type can route when room id exists")
  func payloadWithoutTypeRoutesWithRoomID() {
    let route = PushNotificationRouteParser.route(from: [
      "roomId": "room-2",
    ])

    #expect(route == .chatRoom(roomID: "room-2"))
  }
}
