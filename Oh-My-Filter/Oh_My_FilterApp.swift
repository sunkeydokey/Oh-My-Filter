//
//  Oh_My_FilterApp.swift
//  Oh-My-Filter
//
//  Created by 이선기 on 4/22/26.
//

import SwiftUI

@main
struct OhMyFilterApp: App {
  @State private var coordinator = AppCoordinator(
    loginService: LiveLoginService(),
    signupService: LiveSignupService()
  )

  var body: some Scene {
    WindowGroup {
      ContentView(coordinator: coordinator)
    }
  }
}
