import HomeKit
import SwiftUI

/// My rooms from Apple Home, read on the phone through HomeKit. Hutch only reads room names:
/// it never controls accessories, and the names are kept in memory or, once picked, inside
/// an encrypted item.
@MainActor @Observable
final class HomeRooms: NSObject, HMHomeManagerDelegate {
    private(set) var names: [String] = []
    private var manager: HMHomeManager?

    /// Asks for Home access the first time; until then, and if I decline, there are no rooms.
    func start() {
        guard manager == nil else { return }
        let manager = HMHomeManager()
        manager.delegate = self
        self.manager = manager
    }

    nonisolated func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        let names = manager.homes.flatMap { $0.rooms.map(\.name) }
        Task { @MainActor in self.names = names }
    }
}
