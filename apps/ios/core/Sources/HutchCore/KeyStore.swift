import CryptoKit
import Foundation
import Security

public protocol KeyStore: Sendable {
  func loadOrCreateKey() throws -> SymmetricKey
}

/// The inventory key in the Keychain, on this device only.
public struct KeychainKeyStore: KeyStore {
  // `ThisDeviceOnly` until sync and recovery land together in H3 (D21). `AfterFirstUnlock` so a
  // save never fails if the screen locks mid-save.
  private let service: String
  private let account = "inventory-key"

  public init(service: String = "app.myhutch.ios") {
    self.service = service
  }

  public func loadOrCreateKey() throws -> SymmetricKey {
    if let existing = try read() { return existing }
    let key = Vault.makeKey()
    try write(key)
    return key
  }

  private var query: [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecUseDataProtectionKeychain as String: true,
    ]
  }

  private func read() throws -> SymmetricKey? {
    var q = query
    q[kSecReturnData as String] = true
    q[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: AnyObject?
    let status = SecItemCopyMatching(q as CFDictionary, &result)
    switch status {
    case errSecSuccess:
      guard let data = result as? Data, data.count == 32 else { throw KeyStoreError.malformedKey }
      return SymmetricKey(data: data)
    case errSecItemNotFound:
      return nil
    default:
      throw KeyStoreError.keychain(status)
    }
  }

  private func write(_ key: SymmetricKey) throws {
    var q = query
    q[kSecValueData as String] = key.withUnsafeBytes { Data($0) }
    q[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let status = SecItemAdd(q as CFDictionary, nil)
    guard status == errSecSuccess else { throw KeyStoreError.keychain(status) }
  }

  public func deleteKey() {
    SecItemDelete(query as CFDictionary)
  }
}

public struct InMemoryKeyStore: KeyStore {
  private let key: SymmetricKey

  public init(key: SymmetricKey = Vault.makeKey()) {
    self.key = key
  }

  public func loadOrCreateKey() throws -> SymmetricKey { key }
}

public enum KeyStoreError: Error, Equatable {
  case keychain(OSStatus)
  case malformedKey
}
