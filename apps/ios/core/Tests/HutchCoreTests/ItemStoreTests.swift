import CoreGraphics
import CryptoKit
import Foundation
import Testing

@testable import HutchCore

@Suite struct ItemStoreTests {
  let directory = FileManager.default.temporaryDirectory.appending(
    path: "ItemStoreTests-\(UUID().uuidString)"
  )
  let key = Vault.makeKey()
  var store: ItemStore { ItemStore(directory: directory, vault: Vault(key: key)) }

  static let jpegMagic = Data([0xFF, 0xD8, 0xFF])
  static let photo: CGImage = {
    let context = CGContext(
      data: nil,
      width: 400,
      height: 300,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpace(name: CGColorSpace.sRGB)!,
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
    context.setFillColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
    return context.makeImage()!
  }()

  func drill(at date: Date = .now) -> Item {
    Item(name: "DeWalt drill sentinel", room: "Garage sentinel", createdAt: date)
  }

  @Test func savedItemsComeBack() async throws {
    let item = drill()
    try await store.save(item, photo: Self.photo)
    #expect(try await store.items() == [item])
    let photo = try #require(PhotoEncoder.image(from: try await store.photo(of: item)))
    let thumbnail = try #require(PhotoEncoder.image(from: try await store.thumbnail(of: item)))
    #expect(photo.width == 400)
    #expect(thumbnail.width == PhotoEncoder.thumbnailMaxPixels)
  }

  // Non-negotiable 1.
  @Test func nothingOnDiskIsReadable() async throws {
    try await store.save(drill(), photo: Self.photo)
    let files = try FileManager.default.contentsOfDirectory(
      at: directory,
      includingPropertiesForKeys: nil
    )
    #expect(files.count == 3)
    for file in files {
      let bytes = try Data(contentsOf: file)
      #expect(
        bytes.range(of: Data("sentinel".utf8)) == nil,
        "\(file.lastPathComponent) holds the name or place"
      )
      #expect(bytes.range(of: Data("\"name\"".utf8)) == nil, "\(file.lastPathComponent) holds JSON")
      #expect(bytes.range(of: Self.jpegMagic) == nil, "\(file.lastPathComponent) holds a JPEG")
      #expect(!file.lastPathComponent.contains("DeWalt"))
    }
  }

  @Test func anotherKeyCantRead() async throws {
    try await store.save(drill(), photo: Self.photo)
    let stranger = ItemStore(directory: directory, vault: Vault(key: Vault.makeKey()))
    await #expect(throws: (any Error).self) { try await stranger.items() }
  }

  @Test func swappedFilesDontOpen() async throws {
    let first = drill(), second = drill()
    try await store.save(first, photo: Self.photo)
    try await store.save(second, photo: Self.photo)
    let a = directory.appending(path: "\(first.id.uuidString).photo")
    let b = directory.appending(path: "\(second.id.uuidString).photo")
    try FileManager.default.removeItem(at: b)
    try FileManager.default.copyItem(at: a, to: b)
    await #expect(throws: (any Error).self) { try await store.photo(of: second) }
  }

  @Test func newestFirst() async throws {
    let old = drill(at: .now.addingTimeInterval(-60)), new = drill()
    try await store.save(old, photo: Self.photo)
    try await store.save(new, photo: Self.photo)
    #expect(try await store.items().map(\.id) == [new.id, old.id])
  }

  @Test func deleteRemovesEveryFile() async throws {
    let item = drill()
    try await store.save(item, photo: Self.photo)
    try await store.delete(item)
    #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path).isEmpty)
  }

  @Test func emptyWhenNothingSaved() async throws {
    #expect(try await store.items().isEmpty)
  }
}
