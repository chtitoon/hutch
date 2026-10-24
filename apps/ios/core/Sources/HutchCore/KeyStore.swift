import CryptoKit
import Foundation
import Security

/// Where the inventory key lives.
public protocol KeyStore: Sendable {
    /// The inventory key, created on first use.
    func loadOrCreateKey() throws -> SymmetricKey
}

/// The inventory key in the Keychain, readable after the phone's first unlock, on this device only.
///
/// `ThisDeviceOnly` for H1: the items are on this phone only too, so losing the phone loses
/// both, and nothing can be lost that a backup would have kept readable. H3 moves the key
/// to a synchronizable item in iCloud Keychain with a recovery kit (D21), together with
/// sync (non-negotiable 4). `AfterFirstUnlock` rather than `WhenUnlocked` so saving an item
/// never fails if the screen locks mid-save.
public struct KeychainKeyStore: KeyStore {
    private let service: String
    private let account = "inventory-key"

    public init(service: String = "app.myhutch.ios") {
        self.service = service
    }

    public func loadOrCreateKey() throws -> SymmetricKey {
        if let existing = try read() { return existing }
        let key = Vault.newKey()
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

    /// Removes the key, for tests.
    public func delete() {
        SecItemDelete(query as CFDictionary)
    }
}

/// A key held in memory, for tests and previews.
public struct InMemoryKeyStore: KeyStore {
    private let key: SymmetricKey

    public init(key: SymmetricKey = Vault.newKey()) {
        self.key = key
    }

    public func loadOrCreateKey() throws -> SymmetricKey { key }
}

public enum KeyStoreError: Error, Equatable {
    case keychain(OSStatus)
    case malformedKey
}
