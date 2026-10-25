import CryptoKit
import Foundation

/// Seals and opens bytes with AES-256-GCM from CryptoKit (non-negotiable 3).
///
/// GCM is authenticated, so a changed byte fails to open. The `context` is authenticated too,
/// so one item's file can't be swapped in for another's.
public struct Vault: Sendable {
  private let key: SymmetricKey

  public init(key: SymmetricKey) {
    self.key = key
  }

  public static func makeKey() -> SymmetricKey {
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
