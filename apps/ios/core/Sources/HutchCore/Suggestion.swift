import CoreGraphics
import Foundation

/// What the phone guessed from a photo, for me to confirm or fix.
public struct Suggestion: Sendable, Equatable {
    public var name: String
    public var category: String
    /// Up to three one-tap questions to pin down what the photo can't show (which model, chip,
    /// memory; which style or material).
    public var questions: [Question]
    public var source: SuggestionSource
    /// Why Apple Intelligence wasn't used, when it wasn't: shown under the name, so a poor
    /// guess can be told apart from a model that never ran.
    public var fallbackReason: String?

    public init(name: String, category: String = "", questions: [Question] = [], source: SuggestionSource, fallbackReason: String? = nil) {
        self.name = name
        self.category = category
        self.questions = questions
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

/// A question with a few likely answers, so narrowing down takes a tap, not typing.
public struct Question: Sendable, Equatable, Hashable {
    /// "Chip and year".
    public var label: String
    /// "M1, 2020", "M2, 2022", "M3, 2024": most likely first.
    public var choices: [String]

    public init(label: String, choices: [String]) {
        self.label = label
        self.choices = choices
    }

    /// Questions worth showing: a label and 2 to 5 distinct, non-empty choices; at most three.
    static func cleaned(_ questions: [Question]) -> [Question] {
        questions.compactMap { question in
            let label = question.label.trimmingCharacters(in: .whitespacesAndNewlines)
            var seen = Set<String>()
            let choices = question.choices
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                // Not answering is "not sure", so those choices are noise.
                .filter { !$0.isEmpty && !["unknown", "not sure", "don't know", "other"].contains($0.lowercased()) }
                .filter { seen.insert($0.lowercased()).inserted }
            guard !label.isEmpty, choices.count >= 2 else { return nil }
            return Question(label: label, choices: Array(choices.prefix(5)))
        }
        .prefix(3)
        .map { $0 }
    }
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

    /// Labels that describe a scene, surface or material rather than a thing.
    static let generic: Set<String> = [
        "structure", "material", "indoor", "outdoor", "room", "wood_processed", "wood_natural", "wood",
        "textile", "machine", "tool", "equipment", "consumer_electronics", "container", "interior_room",
        "floor", "wall", "garage", "shelf", "table", "desk", "object", "furniture", "plastic", "metal",
        "office", "workplace", "hardwood", "wood_grain", "fabric", "paper", "document", "screenshot",
    ]

    /// Labels that may name the object itself, most confident first.
    public var objectLabels: [String] { labels.filter { !Self.generic.contains($0) } }
    /// Labels about the scene or material around it.
    public var sceneLabels: [String] { labels.filter { Self.generic.contains($0) } }

    /// Text that looks printed on the object, like a brand or a spec: short lines only. A
    /// screen or a page in the photo gives long lines and many of them, which say nothing
    /// about what the object is.
    public var printedText: [String] {
        text.filter { $0.split(separator: " ").count <= 4 }.prefix(6).map { $0 }
    }

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
        printedText.lazy
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
