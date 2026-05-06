import Testing
@testable import Oh_My_Filter

struct AuthenticatedRootNavigationTests {
  @Test("created filter replaces make route with detail route")
  func createdFilterReplacesMakeRouteWithDetailRoute() {
    var path: [MainRoute] = [.filterMake]

    MainNavigationPathReducer.replaceFilterMakeWithDetail("filter-123", in: &path)

    #expect(path == [.filterDetail(filterID: "filter-123")])
  }
}
