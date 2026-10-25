import Foundation

/// One thing I own: a name, a room and an optional spot. Stored only on this device,
/// encrypted (see `ItemStore`), and private: nothing can share it yet (non-negotiable 2).
public struct Item: Codable, Identifiable, Sendable, Equatable {
    /// Names its encrypted files.
    public let id: UUID
    public var name: String
    /// The room it lives in, from Apple Home or one I've used: "Garage".
    public var room: String
    /// Where in the room, optional: "left shelf".
    public var spot: String
    /// Orders "Added lately".
    public let createdAt: Date

    public init(id: UUID = UUID(), name: String, room: String = "", spot: String = "", createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.room = room
        self.spot = spot
        self.createdAt = createdAt
    }

    /// Reads items saved by any earlier build: fields dropped since are ignored, and an early
    /// build's single `place` becomes the room. An item that won't decode would hide every
    /// other one, so nothing here is required beyond its id, name and date.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        room = try c.decodeIfPresent(String.self, forKey: .room) ?? c.decodeIfPresent(String.self, forKey: .place) ?? ""
        spot = try c.decodeIfPresent(String.self, forKey: .spot) ?? ""
        createdAt = try c.decode(Date.self, forKey: .createdAt)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(room, forKey: .room)
        try c.encode(spot, forKey: .spot)
        try c.encode(createdAt, forKey: .createdAt)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, room, spot, createdAt
        /// An early build's room and spot in one string.
        case place
    }
}

extension Item {
    /// "Garage · left shelf", "Garage", or empty.
    public var place: String {
        [room, spot]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    /// Rooms to offer: those I've used, most recent first, then my Apple Home rooms; each
    /// once, ignoring case and surrounding spaces.
    public static func rooms(used items: [Item], home: [String] = []) -> [String] {
        var seen = Set<String>()
        let used = items.sorted { $0.createdAt > $1.createdAt }.map(\.room)
        return (used + home)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }
}
