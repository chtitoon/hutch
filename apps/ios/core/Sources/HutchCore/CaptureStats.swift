import Foundation

/// H1's and X4's signals, counted from my own items on my phone, never sent (non-negotiable 5).
public struct CaptureStats: Equatable, Sendable {
    /// H1: each item added in under this many seconds.
    public static let targetSeconds = 20.0

    public var itemCount: Int
    /// Items with a capture record (added through the camera flow).
    public var timedCount: Int
    public var medianSeconds: Double?
    public var underTargetCount: Int
    /// Items that had a suggestion, and how many of those kept its name as is (X4).
    public var suggestedCount: Int
    public var keptSuggestionCount: Int
    public var medianSuggestionSeconds: Double?

    public init(items: [Item]) {
        let records = items.compactMap(\.capture)
        let suggested = records.filter { $0.suggestionSource != .none }
        itemCount = items.count
        timedCount = records.count
        medianSeconds = Self.median(records.map(\.seconds))
        underTargetCount = records.count { $0.seconds < Self.targetSeconds }
        suggestedCount = suggested.count
        keptSuggestionCount = suggested.count(where: \.keptSuggestedName)
        medianSuggestionSeconds = Self.median(suggested.compactMap(\.suggestionSeconds))
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
}
