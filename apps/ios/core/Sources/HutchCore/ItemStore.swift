import CoreGraphics
import Foundation

/// The inventory on disk, every file sealed by a ``Vault`` (non-negotiable 1).
public actor ItemStore {
  private let directory: URL
  private let vault: Vault

  public init(directory: URL, vault: Vault) {
    self.directory = directory
    self.vault = vault
  }

  public static func onDevice(keyStore: some KeyStore = KeychainKeyStore()) throws -> ItemStore {
    let support = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let vault = Vault(key: try keyStore.loadOrCreateKey())
    return ItemStore(
      directory: support.appending(path: "Items", directoryHint: .isDirectory),
      vault: vault
    )
  }

  public func items() throws -> [Item] {
    guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
    return try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil
    )
    .filter { $0.pathExtension == File.record.rawValue }
    .compactMap { UUID(uuidString: $0.deletingPathExtension().lastPathComponent) }
    .map { try JSONDecoder().decode(Item.self, from: read(.record, of: $0)) }
    .sorted { $0.createdAt > $1.createdAt }
  }

  public func save(_ item: Item, photo: CGImage) throws {
    let photoData = try PhotoEncoder.jpeg(photo, maxPixels: PhotoEncoder.photoMaxPixels)
    let thumbnailData = try PhotoEncoder.jpeg(photo, maxPixels: PhotoEncoder.thumbnailMaxPixels)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    // The record goes last, so an item never appears without its pictures.
    try write(photoData, as: .photo, of: item.id)
    try write(thumbnailData, as: .thumbnail, of: item.id)
    try write(JSONEncoder().encode(item), as: .record, of: item.id)
  }

  public func photo(of item: Item) throws -> Data {
    try read(.photo, of: item.id)
  }

  public func thumbnail(of item: Item) throws -> Data {
    try read(.thumbnail, of: item.id)
  }

  public func delete(_ item: Item) throws {
    // The record goes first, so a failure part-way never leaves an item without its photo.
    for file in [File.record, .photo, .thumbnail] {
      let url = url(of: file, for: item.id)
      if FileManager.default.fileExists(atPath: url.path) {
        try FileManager.default.removeItem(at: url)
      }
    }
  }

  enum File: String {
    case record = "item"
    case photo
    case thumbnail = "thumb"
  }

  private func url(of file: File, for id: Item.ID) -> URL {
    directory.appending(path: "\(id.uuidString).\(file.rawValue)")
  }

  // Binds each ciphertext to its item and file, so files can't be swapped.
  private func context(of file: File, for id: Item.ID) -> String {
    "\(id.uuidString).\(file.rawValue)"
  }

  private func write(_ plaintext: Data, as file: File, of id: Item.ID) throws {
    let sealed = try vault.seal(plaintext, context: context(of: file, for: id))
    #if os(iOS)
      try sealed.write(
        to: url(of: file, for: id),
        options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
      )
    #else
      try sealed.write(to: url(of: file, for: id), options: .atomic)
    #endif
  }

  private func read(_ file: File, of id: Item.ID) throws -> Data {
    try vault.open(Data(contentsOf: url(of: file, for: id)), context: context(of: file, for: id))
  }
}
