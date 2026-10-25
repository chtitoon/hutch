import Foundation

/// One thing I own. Nothing can share an item yet, so every item is private (non-negotiable 2).
public struct Item: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public var name: String
  public var room: String
  public var spot: String
  public let createdAt: Date

  public init(
    id: UUID = UUID(),
    name: String,
    room: String = "",
    spot: String = "",
    createdAt: Date = .now
  ) {
    self.id = id
    self.name = name
    self.room = room
    self.spot = spot
    self.createdAt = createdAt
  }
}

extension Item {
  public var place: String {
    [room, spot]
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
      .joined(separator: " · ")
  }

  /// Rooms I've used, newest first, then my Apple Home rooms, each once.
  public static func roomSuggestions(from items: [Item], homeRooms home: [String] = []) -> [String]
  {
    var seen = Set<String>()
    let used = items.sorted { $0.createdAt > $1.createdAt }.map(\.room)
    return (used + home)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
  }
}
