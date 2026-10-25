import HutchCore
import SwiftUI

@MainActor
@Observable
final class Library {
  private(set) var items: [Item]
  var error: String?
  let homeRooms = HomeRooms()

  private let store: ItemStore?
  private var thumbnails: [Item.ID: UIImage]

  init(store: ItemStore?, items: [Item] = [], thumbnails: [Item.ID: UIImage] = [:]) {
    self.store = store
    self.items = items
    self.thumbnails = thumbnails
  }

  static func onDevice() -> Library {
    do {
      let library = Library(store: try ItemStore.onDevice())
      Task { await library.load() }
      return library
    } catch {
      let library = Library(store: nil)
      library.error =
        "Hutch couldn't open its encrypted storage, so nothing can be saved. (\(error.localizedDescription))"
      return library
    }
  }

  var rooms: [String] {
    Item.roomSuggestions(from: items, homeRooms: homeRooms.names)
  }

  func items(in room: String) -> [Item] {
    items.filter { $0.room == room }
  }

  func thumbnail(of item: Item) -> UIImage? {
    thumbnails[item.id]
  }

  func load() async {
    guard let store else { return }
    do {
      items = try await store.items()
      for item in items {
        thumbnails[item.id] = UIImage(data: try await store.thumbnail(of: item))
      }
    } catch {
      self.error = "Hutch couldn't read your items. (\(error.localizedDescription))"
    }
  }

  func add(_ item: Item, photo: CGImage) async throws {
    guard let store else { throw LibraryError.noStorage }
    try await store.save(item, photo: photo)
    items.insert(item, at: 0)
    thumbnails[item.id] = UIImage(data: try await store.thumbnail(of: item))
  }

  // Decrypted only while a screen shows it.
  func photo(of item: Item) async throws -> UIImage? {
    guard let store else { return nil }
    return UIImage(data: try await store.photo(of: item))
  }

  func delete(_ item: Item) async throws {
    try await store?.delete(item)
    items.removeAll { $0.id == item.id }
    thumbnails[item.id] = nil
  }
}

enum LibraryError: LocalizedError {
  case noStorage

  var errorDescription: String? {
    "Hutch's encrypted storage isn't available."
  }
}
