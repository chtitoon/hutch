import CoreGraphics
import Foundation

/// What the phone guessed from a photo, for me to confirm or fix.
public struct Suggestion: Sendable, Equatable {
    public var name: String
    public var category: String
    public var source: SuggestionSource
    /// Why Apple Intelligence wasn't used, when it wasn't: shown under the name, so a poor
    /// guess can be told apart from a model that never ran.
    public var fallbackReason: String?

    public init(name: String, category: String = "", source: SuggestionSource, fallbackReason: String? = nil) {
        self.name = name
        self.category = category
        self.source = source
        self.fallbackReason = fallbackReason
    }

    /// Names a model gives when it can't tell, which are no suggestion at all.
    static func isPlaceholder(_ name: String) -> Bool {
        let words = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return words.isEmpty || ["unknown", "unknow", "unknown object", "object", "item", "thing", "n/a", "none"].contains(words)
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
    func suggest(for image: CGImage) async -> Suggestion
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

    /// A name without a language model: a brand read on the object, then the most confident
    /// specific label, made readable. "power_drill" with "DEWALT" on it becomes "DEWALT Power drill".
    public var fallbackName: String {
        let label = (labels.first { !Self.generic.contains($0) } ?? labels.first).map(Self.readable) ?? ""
        guard let brand, !label.localizedCaseInsensitiveContains(brand) else { return label }
        return label.isEmpty ? brand : "\(brand) \(label)"
    }

    /// The first word in the text that looks like a brand: letters only, 3 to 14 of them,
    /// with a capital, and not one of the words printed on every label.
    public var brand: String? {
        text.lazy
            .flatMap { $0.split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "-" }) }
            .map(String.init)
            .first { word in
                (3...14).contains(word.count)
                    && word.allSatisfy(\.isLetter)
                    && word.contains(where: \.isUppercase)
                    && !Self.labelWords.contains(word.lowercased())
            }
    }

    /// Words printed on chargers, tools and boxes that are never the brand.
    static let labelWords: Set<String> = [
        "input", "output", "model", "made", "china", "designed", "power", "volt", "volts", "watt", "watts",
        "warning", "caution", "danger", "charger", "charging", "charge", "fast", "quick", "battery", "adapter",
        "class", "serial", "type", "usb", "max", "only", "use", "indoor", "outdoor", "with", "for", "and", "the",
        "certified", "listed", "rated", "new", "pro", "plus", "mini", "series", "item", "size", "color",
        "assembled", "contents", "lot", "date", "ref", "art", "patent", "pending", "tested", "approved",
    ]

    static func readable(_ identifier: String) -> String {
        let words = identifier.replacingOccurrences(of: "_", with: " ").trimmingCharacters(in: .whitespaces)
        return words.prefix(1).uppercased() + words.dropFirst()
    }

    /// The suggestion when no language model is available, saying why.
    public func fallbackSuggestion(because reason: String) -> Suggestion {
        let name = fallbackName
        return Suggestion(name: name, source: name.isEmpty ? .none : .labelsOnly, fallbackReason: reason)
    }
}
