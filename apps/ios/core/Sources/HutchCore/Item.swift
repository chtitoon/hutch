import Foundation

/// One thing I own. Nothing can share an item yet, so every item is private (non-negotiable 2).
///
/// Its photo and thumbnail are files of their own in ``ItemStore``, with the item's id, so
/// listing items never decrypts every photo. Like SwiftData's `.externalStorage`.
public struct Item: Codable, Identifiable, Hashable, Sendable {
  public let id: UUID
  public var name: String {
    didSet { name = Item.sentenceCased(name) }
  }
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
    self.name = Item.sentenceCased(name)
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

  /// "cordless drill" becomes "Cordless drill". The rest stays as typed, and names like
  /// "iPhone case" keep their brand's casing.
  static func sentenceCased(_ name: String) -> String {
    let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let first = name.first, first.isLowercase else { return name }
    if let second = name.dropFirst().first, second.isUppercase { return name }
    return first.uppercased() + name.dropFirst()
  }
}
