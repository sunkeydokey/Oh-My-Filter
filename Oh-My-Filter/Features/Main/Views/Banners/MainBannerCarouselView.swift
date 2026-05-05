import SwiftUI

struct MainBannerCarouselView: View {
  let banners: [MainBanner]

  @State private var selectedBanner: MainBanner?
  @State private var attendanceResult: AttendanceSuccess?

  var body: some View {
    TabView {
      ForEach(banners) { banner in
        Button {
          guard banner.webViewURL != nil else { return }
          selectedBanner = banner
        } label: {
          MainBannerCardView(banner: banner)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
      }
    }
    .frame(maxWidth: .infinity)
    .frame(height: 110)
    .tabViewStyle(.page(indexDisplayMode: .never))
    .fullScreenCover(item: $selectedBanner) { banner in
      if let url = banner.webViewURL {
        BannerWebView(
          url: url,
          onComplete: { count in
            attendanceResult = AttendanceSuccess(count: count)
            selectedBanner = nil
          },
          onDismiss: {
            selectedBanner = nil
          }
        )
        .ignoresSafeArea()
      }
    }
    .overlay {
      if let result = attendanceResult {
        CustomAlertSingleButtonView(
          title: "출석 완료!",
          message: "\(result.count)번째 출석이 완료되었습니다.",
          confirmTitle: "확인"
        ) {
          attendanceResult = nil
        }
      }
    }
  }
}

private struct AttendanceSuccess: Identifiable, Equatable {
  let id = UUID()
  let count: Int
}
