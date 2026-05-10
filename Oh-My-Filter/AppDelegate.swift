import SwiftUI
import FirebaseCore
import FirebaseMessaging
import KakaoSDKCommon
import UserNotifications

@MainActor
enum AppOrientationLock {
  static var supportedOrientations: UIInterfaceOrientationMask = .portrait
}

final class AppDelegate: NSObject, UIApplicationDelegate {
  private let deviceTokenStore: any DeviceTokenStoring = AppDeviceTokenStore()

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    FirebaseApp.configure()
    KakaoSDK.initSDK(appKey: Self.kakaoNativeAppKey())

    UNUserNotificationCenter.current().delegate = self
    Messaging.messaging().delegate = self

    let options: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(options: options) { _, _ in }

    application.registerForRemoteNotifications()
    return true
  }

  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    MainActor.assumeIsolated {
      AppOrientationLock.supportedOrientations
    }
  }

  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    Messaging.messaging().token { token, error in
        if let error = error {
            print("FCM token error: \(error)")
            return
        }
        if let token {
          self.deviceTokenStore.saveDeviceToken(token)
        }
        print("FCM token: \(token ?? "nil")")
    }  }

  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("APNs registration failed: \(error)")
  }
}

private extension AppDelegate {
  static func kakaoNativeAppKey() -> String {
    let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_API_KEY") as? String
      ?? kakaoURLScheme()

    if key.hasPrefix("kakao") {
      return String(key.dropFirst("kakao".count))
    }

    return key
  }

  static func kakaoURLScheme() -> String {
    guard
      let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]],
      let schemes = urlTypes.compactMap({ $0["CFBundleURLSchemes"] as? [String] }).first,
      let scheme = schemes.first
    else {
      return ""
    }

    return scheme
  }
}

extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    if let fcmToken {
      AppDeviceTokenStore().saveDeviceToken(fcmToken)
    }
    print("function called:", #function)
    print("FCM token: \(fcmToken ?? "nil")")
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    NotificationCenter.default.post(name: .pushNotificationReceived, object: nil, userInfo: ["payload": userInfo])
    completionHandler([.banner, .badge, .sound])
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("Push tapped: \(userInfo)")
    NotificationCenter.default.post(name: .pushNotificationReceived, object: nil, userInfo: ["payload": userInfo])
    Task { @MainActor in
      PushNotificationRoutingStore.shared.receive(userInfo: userInfo)
      completionHandler()
    }
  }
}
