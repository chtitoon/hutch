import Foundation

/// One thing I own. Stored only on this device, encrypted (see `ItemStore`).
public struct Item: Codable, Identifiable, Sendable, Equatable {
    public let id: UUID
    public var name: String
    /// The model's guess, kept but not shown yet: browsing, lending and selling will use it.
    public var category: String
    /// The room it lives in, from Apple Home or one I've used: "Garage".
    public var room: String
    /// Where in the room, optional: "left shelf".
    public var spot: String
    /// What the photo couldn't show, answered in one tap: "Chip and year: M2, 2022".
    public var details: [Detail]
    /// Who can see it. Always `.private` when created (non-negotiable 2); only an explicit action changes it.
    public private(set) var visibility: Visibility
    public let createdAt: Date
    /// How adding it went, for H1's and X4's signals. Never leaves the device.
    public var capture: CaptureRecord?

    /// New items are private: there is deliberately no `visibility` parameter.
    public init(
        id: UUID = UUID(),
        name: String,
        category: String = "",
        room: String = "",
        spot: String = "",
        details: [Detail] = [],
        createdAt: Date = .now,
        capture: CaptureRecord? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.room = room
        self.spot = spot
        self.details = details
        self.visibility = .private
        self.createdAt = createdAt
        self.capture = capture
    }

    /// Reads items saved by any earlier build: fields added since default to empty, and the
    /// first build's single `place` becomes the room. An item that won't decode would hide
    /// every other one, so nothing here is required beyond its id, name and date.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        room = try c.decodeIfPresent(String.self, forKey: .room) ?? c.decodeIfPresent(String.self, forKey: .place) ?? ""
        spot = try c.decodeIfPresent(String.self, forKey: .spot) ?? ""
        details = try c.decodeIfPresent([Detail].self, forKey: .details) ?? []
        visibility = try c.decodeIfPresent(Visibility.self, forKey: .visibility) ?? .private
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        capture = try c.decodeIfPresent(CaptureRecord.self, forKey: .capture)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(category, forKey: .category)
        try c.encode(room, forKey: .room)
        try c.encode(spot, forKey: .spot)
        try c.encode(details, forKey: .details)
        try c.encode(visibility, forKey: .visibility)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encodeIfPresent(capture, forKey: .capture)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, category, room, spot, details, visibility, createdAt, capture
        /// The first build's room and spot in one string.
        case place
    }
}

/// One question the photo couldn't answer, and my answer.
public struct Detail: Codable, Sendable, Equatable, Hashable {
    /// "Chip and year".
    public var question: String
    /// "M2, 2022".
    public var answer: String

    public init(question: String, answer: String) {
        self.question = question
        self.answer = answer
    }
}

public enum Visibility: String, Codable, Sendable {
    case `private`
    case lendable
    case forSale
}

/// Measured while adding an item, kept with it, never sent anywhere.
public struct CaptureRecord: Codable, Sendable, Equatable {
    /// From the shutter to Save.
    public var seconds: Double
    /// From the shutter to the suggestion appearing, if one did.
    public var suggestionSeconds: Double?
    public var suggestionSource: SuggestionSource
    /// Whether the saved name is the suggested one, unedited (X4's "accept as is").
    public var keptSuggestedName: Bool

    public init(seconds: Double, suggestionSeconds: Double?, suggestionSource: SuggestionSource, keptSuggestedName: Bool) {
        self.seconds = seconds
        self.suggestionSeconds = suggestionSeconds
        self.suggestionSource = suggestionSource
        self.keptSuggestedName = keptSuggestedName
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
