import CoreGraphics
import Foundation

/// What the phone guessed from a photo, for me to confirm or fix.
public struct Suggestion: Sendable, Equatable {
    public var name: String
    public var category: String
    /// A rough resale guess in the currency asked for; nil when the model had none (D23, option 4).
    public var resaleEstimate: Decimal?
    public var source: SuggestionSource

    public init(name: String, category: String = "", resaleEstimate: Decimal? = nil, source: SuggestionSource) {
        self.name = name
        self.category = category
        self.resaleEstimate = resaleEstimate
        self.source = source
    }

    public static let empty = Suggestion(name: "", source: .none)
}

/// Which on-device path made a suggestion, so X4 can compare them. Nothing here leaves the phone.
public enum SuggestionSource: String, Codable, Sendable {
    /// The Foundation Models system model, given the photo itself (iOS 27, on capable phones).
    case modelWithImage
    /// The Foundation Models system model, given what Vision saw and read.
    case modelWithLabels
    /// Vision's labels alone, when Apple Intelligence isn't available.
    case labelsOnly
    /// Nothing usable.
    case none
}

public protocol ItemSuggesting: Sendable {
    func suggest(for image: CGImage, currency: String) async -> Suggestion
}

/// What Vision found in a photo: classification labels and any text on the thing.
public struct VisionFindings: Sendable, Equatable {
    /// Identifiers such as "power_drill", most confident first.
    public var labels: [String]
    /// Lines of text read off the photo, such as a brand or model number.
    public var text: [String]

    public init(labels: [String], text: [String]) {
        self.labels = labels
        self.text = text
    }

    /// Labels that describe a scene or material rather than a thing.
    static let generic: Set<String> = [
        "structure", "material", "indoor", "outdoor", "room", "wood_processed", "wood_natural",
        "textile", "machine", "tool", "equipment", "consumer_electronics", "container", "interior_room",
        "floor", "wall", "garage", "shelf", "table", "object", "furniture", "plastic", "metal",
    ]

    /// A name from the labels alone: the most confident specific label, made readable.
    /// "power_drill" becomes "Power drill".
    public var fallbackName: String {
        let label = labels.first { !Self.generic.contains($0) } ?? labels.first
        return label.map(Self.readable) ?? ""
    }

    static func readable(_ identifier: String) -> String {
        let words = identifier.replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespaces)
        return words.prefix(1).uppercased() + words.dropFirst()
    }

    /// The suggestion when no language model is available.
    public var fallbackSuggestion: Suggestion {
        let name = fallbackName
        return name.isEmpty ? .empty : Suggestion(name: name, source: .labelsOnly)
    }
}
