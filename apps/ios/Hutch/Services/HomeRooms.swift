import HomeKit
import SwiftUI

/// Room names from Apple Home. Hutch never controls accessories (D25).
@MainActor @Observable
final class HomeRooms: NSObject, HMHomeManagerDelegate {
  private(set) var names: [String] = []
  private var manager: HMHomeManager?

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
