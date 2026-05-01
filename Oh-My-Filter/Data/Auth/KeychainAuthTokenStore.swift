import Foundation
import Security

actor KeychainAuthTokenStore {
  private let service: String
  private let account: String
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init(
    service: String? = nil,
    account: String = "authTokens",
    encoder: JSONEncoder = JSONEncoder(),
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.service = service ?? "Oh-My-Filter"
    self.account = account
    self.encoder = encoder
    self.decoder = decoder
  }

  func save(_ tokens: StoredAuthTokens) async throws {
    let data = try encoder.encode(tokens)
    var query = baseQuery
    query[kSecValueData as String] = data
    query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    let status = SecItemAdd(query as CFDictionary, nil)
    if status == errSecDuplicateItem {
      let updateStatus = SecItemUpdate(baseQuery as CFDictionary, [
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      ] as CFDictionary)
      guard updateStatus == errSecSuccess else {
        throw KeychainAuthTokenStoreError.unhandledStatus(updateStatus)
      }
      return
    }

    guard status == errSecSuccess else {
      throw KeychainAuthTokenStoreError.unhandledStatus(status)
    }
  }

  func tokens() async throws -> StoredAuthTokens? {
    var query = baseQuery
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)

    if status == errSecItemNotFound {
      return nil
    }

    guard status == errSecSuccess else {
      throw KeychainAuthTokenStoreError.unhandledStatus(status)
    }

    guard let data = item as? Data else {
      throw KeychainAuthTokenStoreError.invalidData
    }

    return try decoder.decode(StoredAuthTokens.self, from: data)
  }

  func delete() async throws {
    let status = SecItemDelete(baseQuery as CFDictionary)

    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainAuthTokenStoreError.unhandledStatus(status)
    }
  }

  private var baseQuery: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }
}

enum KeychainAuthTokenStoreError: Error, Equatable, Sendable {
  case invalidData
  case unhandledStatus(OSStatus)
}

extension KeychainAuthTokenStore: AuthTokenStoring {}
