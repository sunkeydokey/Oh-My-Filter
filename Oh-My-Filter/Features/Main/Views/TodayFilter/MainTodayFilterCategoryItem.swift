import Foundation

struct MainTodayFilterCategoryItem: Identifiable {
  let title: String
  let systemImage: String

  var id: String { title }
}
