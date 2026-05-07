import Foundation

nonisolated protocol UserSessionStoring: Sendable {
  func currentUserID() -> String?
  func localDataOwnerUserID() -> String?
  func saveAuthenticatedUserID(_ userID: String)
  func clearCurrentUserID()
}

nonisolated struct AppUserSessionStore: UserSessionStoring, @unchecked Sendable {
  private let defaults: UserDefaults
  private let currentUserIDKey: String
  private let localDataOwnerUserIDKey: String

  init(
    defaults: UserDefaults = .standard,
    currentUserIDKey: String = "app.currentUserID",
    localDataOwnerUserIDKey: String = "app.localDataOwnerUserID"
  ) {
    self.defaults = defaults
    self.currentUserIDKey = currentUserIDKey
    self.localDataOwnerUserIDKey = localDataOwnerUserIDKey
  }

  func currentUserID() -> String? {
    defaults.string(forKey: currentUserIDKey)
  }

  func localDataOwnerUserID() -> String? {
    defaults.string(forKey: localDataOwnerUserIDKey)
  }

  func saveAuthenticatedUserID(_ userID: String) {
    defaults.set(userID, forKey: currentUserIDKey)
    defaults.set(userID, forKey: localDataOwnerUserIDKey)
  }

  func clearCurrentUserID() {
    defaults.removeObject(forKey: currentUserIDKey)
  }
}
