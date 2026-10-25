import HutchCore
import SwiftUI

/// The inventory as the screens see it: items and thumbnails in memory, saved through the
/// encrypted `ItemStore`.
@MainActor @Observable
final class Library {
    private(set) var items: [Item] = []
    private(set) var thumbnails: [UUID: UIImage] = [:]
    private(set) var error: String?
    private let store: ItemStore?
    let homeRooms = HomeRooms()

    init(store: ItemStore?) {
        self.store = store
    }

    static func onDevice() -> Library {
        do {
            let library = Library(store: try ItemStore.onDevice())
            Task { await library.load() }
            return library
        } catch {
            let library = Library(store: nil)
            library.error = "Hutch couldn't open its encrypted storage, so nothing can be saved. (\(error.localizedDescription))"
            return library
        }
    }

    /// Rooms I've used, then the rest of my Apple Home rooms.
    var rooms: [String] { Item.rooms(used: items, home: homeRooms.names) }

    func load() async {
        guard let store else { return }
        do {
            items = try await store.items()
            for item in items {
                if let data = try? await store.thumbnail(of: item.id), let image = UIImage(data: data) {
                    thumbnails[item.id] = image
                }
            }
        } catch {
            self.error = "Hutch couldn't read your items. (\(error.localizedDescription))"
        }
    }

    func add(_ item: Item, photo: CGImage) async throws {
        guard let store else { throw LibraryError.noStorage }
        let jpeg = try PhotoEncoder.jpeg(photo, maxPixels: PhotoEncoder.photoMaxPixels)
        let thumb = try PhotoEncoder.jpeg(photo, maxPixels: PhotoEncoder.thumbnailMaxPixels)
        try await store.save(item, photo: jpeg, thumbnail: thumb)
        items.insert(item, at: 0)
        thumbnails[item.id] = UIImage(data: thumb)
    }

    /// The full photo, decrypted only for as long as a screen shows it.
    func photo(of id: UUID) async -> UIImage? {
        guard let data = try? await store?.photo(of: id) else { return nil }
        return UIImage(data: data)
    }

    func delete(_ id: UUID) async {
        try? await store?.delete(id)
        items.removeAll { $0.id == id }
        thumbnails[id] = nil
    }
}

enum LibraryError: LocalizedError {
    case noStorage
    var errorDescription: String? { "Hutch's encrypted storage isn't available." }
}
