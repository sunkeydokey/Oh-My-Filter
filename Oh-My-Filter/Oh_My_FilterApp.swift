//
//  Oh_My_FilterApp.swift
//  Oh-My-Filter
//
//  Created by 이선기 on 4/22/26.
//

import KakaoSDKAuth
import SwiftUI
import UIKit
import iamport_ios

@main
struct OhMyFilterApp: App {
  @State private var coordinator = AppCoordinator(
    loginService: LiveLoginService(),
    signupService: LiveSignupService()
  )

  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  init() {
    TabBarAppearance.configure()
  }

  var body: some Scene {
    WindowGroup {
      ContentView(coordinator: coordinator)
        .preferredColorScheme(.dark)
        .onOpenURL { url in
          if url.scheme == SDK.Payment.appScheme {
            Iamport.shared.receivedURL(url)
          } else {
            AuthController.handleOpenUrl(url: url)
          }
        }
    }
  }
}

private enum TabBarAppearance {
  static func configure() {
    let selectedColor = UIColor(ColorToken.sesacFilterBrightTurquoise.color)
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
