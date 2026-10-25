import CryptoKit
import Foundation

/// Seals and opens bytes with the inventory key.
///
/// AES-256-GCM from CryptoKit (non-negotiable 3): authenticated encryption, so a changed
/// byte fails to open instead of decrypting to garbage. CryptoKit picks a fresh random
/// 96-bit nonce per seal and stores it in the combined output, so nonces never repeat in
/// practice at Hutch's volume. Each seal is bound to a context string (the item's id and
/// what the bytes are) as authenticated data, so one item's file can't be swapped in for
/// another's, or a photo for a record, without failing to open.
public struct Vault: Sendable {
    private let key: SymmetricKey

    public init(key: SymmetricKey) {
        self.key = key
    }

    public static func newKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }

    public func seal(_ plaintext: Data, context: String) throws -> Data {
        let box = try AES.GCM.seal(plaintext, using: key, authenticating: Data(context.utf8))
        // `combined` is nil only for nonces that aren't 12 bytes; CryptoKit's default is 12.
        guard let combined = box.combined else { throw VaultError.unexpectedNonceSize }
        return combined
    }

    public func open(_ sealed: Data, context: String) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: sealed)
        return try AES.GCM.open(box, using: key, authenticating: Data(context.utf8))
    }
}

public enum VaultError: Error {
    case unexpectedNonceSize
}
