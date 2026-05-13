//
//  Oh_My_FilterApp.swift
//  Oh-My-Filter
//
//  Created by 이선기 on 4/22/26.
//

import KakaoSDKAuth
import SwiftData
import SwiftUI
import iamport_ios

@main
struct OhMyFilterApp: App {
  private let modelContainer: ModelContainer
  private let downloadManager: LiveVideoDownloadManager
  @State private var coordinator: AppCoordinator
  @State private var purchasedFilterStore: PurchasedFilterStore

  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  init() {
    do {
      let modelContainer = try ModelContainer(
        for: ChatRoomRecord.self, ChatMessageRecord.self,
             PurchasedFilterRecord.self, OfflineVideoRecord.self
      )
      self.modelContainer = modelContainer
      let offlineStore = SwiftDataOfflineVideoStore(container: modelContainer)
      self.downloadManager = LiveVideoDownloadManager(offlineStore: offlineStore)
      _coordinator = State(initialValue: AppCoordinator(
        loginService: LiveLoginService(),
        signupService: LiveSignupService(),
        localSessionDataResetter: SwiftDataLocalSessionDataResetter(container: modelContainer)
      ))
      _purchasedFilterStore = State(initialValue: PurchasedFilterStore(container: modelContainer))
    } catch {
      fatalError("Failed to create SwiftData model container: \(error)")
    }
    TabBarAppearance.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView(
        coordinator: coordinator,
        pushRoutingStore: PushNotificationRoutingStore.shared
      )
        .preferredColorScheme(.dark)
        .modelContainer(modelContainer)
        .environment(purchasedFilterStore)
        .environment(\.videoDownloadManager, downloadManager)
        .onOpenURL { url in
          if url.scheme == SDK.Payment.appScheme {
            Iamport.shared.receivedURL(url)
          } else {
            _ = AuthController.handleOpenUrl(url: url)
          }
        }
    }
  }
}

private enum TabBarAppearance {
  static func configure() {
    let selectedColor = UIColor(ColorToken.mainAccent.color)
    let normalColor = UIColor(ColorToken.grayScale60.color)
    let backgroundColor = UIColor(ColorToken.brandBlackSprout.color)

    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = backgroundColor

    for layoutAppearance in [
      appearance.stackedLayoutAppearance,
      appearance.inlineLayoutAppearance,
      appearance.compactInlineLayoutAppearance,
    ] {
      layoutAppearance.selected.iconColor = selectedColor
      layoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]
      layoutAppearance.normal.iconColor = normalColor
      layoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
    }

    let tabBar = UITabBar.appearance()
    tabBar.standardAppearance = appearance
    tabBar.scrollEdgeAppearance = appearance
    tabBar.tintColor = selectedColor
    tabBar.unselectedItemTintColor = normalColor
  }
}
