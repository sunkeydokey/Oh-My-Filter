import Foundation

extension IconToken {
  var symbolName: String {
    switch self {
    case .back:
      "chevron.left"
    case .favorite:
      "heart"
    case .favoriteFilled:
      "heart.fill"
    case .secure:
      "lock.fill"
    case .hidden:
      "eye.slash"
    case .send:
      "paperplane.fill"
    case .add:
      "plus"
    case .download:
      "square.and.arrow.down"
    case .controls:
      "slider.horizontal.3"
    case .undo:
      "arrow.uturn.backward"
    case .redo:
      "arrow.uturn.forward"
    case .alarm:
      "bell"
    case .people:
      "person.2"
    case .hiking:
      "figure.hiking"
    case .moonlight:
      "moon.stars"
    case .sparkle:
      "sparkles"
    case .homeFilled:
      "house.fill"
    case .home:
      "house"
    case .boardFilled:
      "square.grid.2x2.fill"
    case .board:
      "square.grid.2x2"
    case .magicFilled:
      "wand.and.stars.inverse"
    case .magic:
      "wand.and.stars"
    case .chat:
      "message.fill"
    case .search:
      "magnifyingglass"
    case .profileFilled:
      "person.fill"
    case .profile:
      "person"
    case .settingsFilled:
      "gearshape.fill"
    case .resize:
      "arrow.up.left.and.arrow.down.right"
    case .status:
      "exclamationmark.circle"
    case .grid:
      "circle.grid.2x2"
    case .warning:
      "exclamationmark.triangle"
    case .progress:
      "circle.dashed"
    case .stop:
      "stop.fill"
    case .texture:
      "circle.dotted"
    case .gauge:
      "gauge"
    case .mood:
      "moon.circle"
    case .temperature:
      "thermometer.medium"
    case .settings:
      "gearshape"
    }
  }

  var displayName: String {
    switch self {
    case .back:
      "Back"
    case .favorite:
      "Favorite"
    case .favoriteFilled:
      "Favorite Fill"
    case .secure:
      "Secure"
    case .hidden:
      "Hidden"
    case .send:
      "Send"
    case .add:
      "Add"
    case .download:
      "Download"
    case .controls:
      "Controls"
    case .undo:
      "Undo"
    case .redo:
      "Redo"
    case .alarm:
      "Alarm"
    case .people:
      "People"
    case .hiking:
      "Hiking"
    case .moonlight:
      "Moonlight"
    case .sparkle:
      "Sparkle"
    case .homeFilled:
      "Home Fill"
    case .home:
      "Home"
    case .boardFilled:
      "Board Fill"
    case .board:
      "Board"
    case .magicFilled:
      "Magic Fill"
    case .magic:
      "Magic"
    case .chat:
      "Chat"
    case .search:
      "Search"
    case .profileFilled:
      "Profile Fill"
    case .profile:
      "Profile"
    case .settingsFilled:
      "Settings Fill"
    case .resize:
      "Resize"
    case .status:
      "Status"
    case .grid:
      "Grid"
    case .warning:
      "Warning"
    case .progress:
      "Progress"
    case .stop:
      "Stop"
    case .texture:
      "Texture"
    case .gauge:
      "Gauge"
    case .mood:
      "Mood"
    case .temperature:
      "Temp"
    case .settings:
      "Settings"
    }
  }

  var groupTitle: String {
    switch self {
    case .back,
      .favorite,
      .favoriteFilled,
      .secure,
      .hidden,
      .send,
      .add,
      .download,
      .controls,
      .undo,
      .redo:
      "Action"
    case .alarm, .people, .hiking, .moonlight, .sparkle:
      "Lifestyle"
    case .homeFilled,
      .home,
      .boardFilled,
      .board,
      .magicFilled,
      .magic,
      .chat,
      .search,
      .profileFilled,
      .profile:
      "Navigation"
    case .settingsFilled,
      .resize,
      .status,
      .grid,
      .warning,
      .progress,
      .stop,
      .texture,
      .gauge,
      .mood,
      .temperature,
      .settings:
      "Utility"
    }
  }

  var sortOrder: Int {
    switch self {
    case .back:
      0
    case .favorite:
      1
    case .favoriteFilled:
      2
    case .secure:
      3
    case .hidden:
      4
    case .send:
      5
    case .add:
      6
    case .download:
      7
    case .controls:
      8
    case .undo:
      9
    case .redo:
      10
    case .alarm:
      11
    case .people:
      12
    case .hiking:
      13
    case .moonlight:
      14
    case .sparkle:
      15
    case .homeFilled:
      16
    case .home:
      17
    case .boardFilled:
      18
    case .board:
      19
    case .magicFilled:
      20
    case .magic:
      21
    case .chat:
      22
    case .search:
      23
    case .profileFilled:
      24
    case .profile:
      25
    case .settingsFilled:
      26
    case .resize:
      27
    case .status:
      28
    case .grid:
      29
    case .warning:
      30
    case .progress:
      31
    case .stop:
      32
    case .texture:
      33
    case .gauge:
      34
    case .mood:
      35
    case .temperature:
      36
    case .settings:
      37
    }
  }
}
