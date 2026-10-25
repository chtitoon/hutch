import Foundation

/// The inventory on disk: every file sealed by the `Vault` before it is written
/// (non-negotiable 1), never a plaintext byte.
///
/// One directory, three files per item, each named by the item's id only:
/// - `<id>.item`: the item as JSON.
/// - `<id>.photo`: the photo as JPEG.
/// - `<id>.thumb`: a small JPEG for the list.
public actor ItemStore {
    private let directory: URL
    private let vault: Vault

    public init(directory: URL, vault: Vault) {
        self.directory = directory
        self.vault = vault
    }

    /// The app's store, in Application Support, keyed from the Keychain.
    public static func onDevice(keyStore: some KeyStore = KeychainKeyStore()) throws -> ItemStore {
        let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return ItemStore(directory: support.appending(path: "Items", directoryHint: .isDirectory), vault: Vault(key: try keyStore.loadOrCreateKey()))
    }

    /// Every item, newest first.
    public func items() throws -> [Item] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        let decoder = JSONDecoder()
        return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == Kind.item.rawValue }
            .compactMap { url in
                guard let id = UUID(uuidString: url.deletingPathExtension().lastPathComponent) else { return nil }
                return try decoder.decode(Item.self, from: read(.item, of: id))
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    public func save(_ item: Item, photo: Data, thumbnail: Data) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        // Photos first: an item file only appears once its pictures are there.
        try write(photo, as: .photo, of: item.id)
        try write(thumbnail, as: .thumb, of: item.id)
        try write(JSONEncoder().encode(item), as: .item, of: item.id)
    }

    public func update(_ item: Item) throws {
        try write(JSONEncoder().encode(item), as: .item, of: item.id)
    }

    public func photo(of id: UUID) throws -> Data {
        try read(.photo, of: id)
    }

    public func thumbnail(of id: UUID) throws -> Data {
        try read(.thumb, of: id)
    }

    public func delete(_ id: UUID) throws {
        for kind in Kind.allCases {
            try? FileManager.default.removeItem(at: url(kind, of: id))
        }
    }

    enum Kind: String, CaseIterable {
        case item, photo, thumb
    }

    private func url(_ kind: Kind, of id: UUID) -> URL {
        directory.appending(path: "\(id.uuidString).\(kind.rawValue)")
    }

    /// Binds the ciphertext to its item and kind (see `Vault`).
    private func context(_ kind: Kind, of id: UUID) -> String {
        "\(id.uuidString).\(kind.rawValue)"
    }

    private func write(_ plaintext: Data, as kind: Kind, of id: UUID) throws {
        let sealed = try vault.seal(plaintext, context: context(kind, of: id))
        #if os(iOS)
        // Also covered by iOS Data Protection while the phone is locked.
        try sealed.write(to: url(kind, of: id), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try sealed.write(to: url(kind, of: id), options: .atomic)
        #endif
    }

    private func read(_ kind: Kind, of id: UUID) throws -> Data {
        try vault.open(Data(contentsOf: url(kind, of: id)), context: context(kind, of: id))
    }
}
