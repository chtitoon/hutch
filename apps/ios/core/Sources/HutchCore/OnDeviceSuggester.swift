import CoreGraphics
import Foundation
import FoundationModels
import OSLog
import Vision

/// Suggests a name and aspects from a photo, entirely on the phone (D5, X4, X5):
/// 1. Vision finds the main object and crops to it, so a box on a shelf isn't read as "bookshelf".
/// 2. In parallel: Vision labels the crop and reads any text on it, and the crop's image
///    embedding is matched against the product catalog, when the app has one.
/// 3. Apple's on-device Foundation Models system model turns all that, and the crop itself
///    where the model can see images, into a name and aspects.
/// 4. A sure catalog match names it; a likely one is offered (`combine`).
///
/// Only `SystemLanguageModel` is used, never Private Cloud Compute, and the catalog is a file
/// on the phone, so the photo never leaves the device. Without Apple Intelligence, the
/// catalog or Vision's labels, with the reason why.
public struct OnDeviceSuggester: ItemSuggesting {
    /// The device's own log (Xcode's console, Console.app), never sent anywhere. Names and
    /// labels are marked private, so they're redacted outside a debugging session.
    static let log = Logger(subsystem: "app.myhutch.ios", category: "suggestions")

    private let catalog: Catalog?
    private let embedder: (any ImageEmbedding)?

    /// Without a catalog and embedder, Apple Intelligence and Vision alone.
    public init(catalog: Catalog? = nil, embedder: (any ImageEmbedding)? = nil) {
        self.catalog = catalog
        self.embedder = embedder
    }

    public func suggest(for image: CGImage) async -> Suggestion {
        let subject = await Self.mainObject(in: image)
        async let seen = Self.see(subject)
        async let matched = matches(for: subject)
        let (findings, matches) = await (seen, matched)
        Self.log.info("Vision labels: \(findings.labels.joined(separator: ", "), privacy: .private); text: \(findings.text.joined(separator: " | "), privacy: .private)")
        Self.log.info("Catalog: \(matches.map { "\($0.name) \(String(format: "%.2f", $0.score))" }.joined(separator: ", "), privacy: .private)")

        let model = SystemLanguageModel.default
        if case .unavailable(let reason) = model.availability {
            let why = Self.explain(reason)
            Self.log.notice("Apple Intelligence unavailable: \(why, privacy: .public)")
            return Self.combine(matches: matches, model: nil, fallback: findings.fallbackSuggestion(because: why))
        }
        do {
            let suggestion = try await Self.ask(model, image: subject, findings: findings, matches: matches)
            if Suggestion.isPlaceholder(suggestion.name) {
                Self.log.notice("The model couldn't name it (\(suggestion.name, privacy: .private))")
                return Self.combine(matches: matches, model: nil, fallback: findings.fallbackSuggestion(because: "Apple Intelligence couldn't tell what this is."))
            }
            return Self.combine(matches: matches, model: suggestion, fallback: suggestion)
        } catch {
            Self.log.error("The model failed: \(String(describing: error), privacy: .public)")
            return Self.combine(matches: matches, model: nil, fallback: findings.fallbackSuggestion(because: "Apple Intelligence failed on this photo."))
        }
    }

    private func matches(for image: CGImage) async -> [CatalogMatch] {
        guard let catalog, let embedder else { return [] }
        do {
            return catalog.matches(for: try await embedder.embed(image))
        } catch {
            Self.log.error("The catalog lookup failed: \(String(describing: error), privacy: .public)")
            return []
        }
    }

    /// Strongest evidence first:
    /// - A sure catalog match names it. Apple Intelligence's aspects and category stay.
    /// - Otherwise Apple Intelligence's name, then Vision's.
    /// - Likely catalog matches that aren't the name become one-tap alternatives.
    static func combine(matches: [CatalogMatch], model: Suggestion?, fallback: Suggestion) -> Suggestion {
        let usable = matches.filter { $0.confidence != .low }
        var suggestion = model ?? fallback
        if let best = usable.first {
            suggestion.catalogScore = best.score
            if best.confidence == .high {
                suggestion.name = best.name
                suggestion.source = .catalog
            } else if model == nil {
                // No model to name it: a likely catalog match beats Vision's broad label.
                suggestion.name = best.name
                suggestion.source = .catalog
            }
        }
        suggestion.alternatives = usable.map(\.name).filter { $0.caseInsensitiveCompare(suggestion.name) != .orderedSame }.prefix(3).map { $0 }
        return suggestion
    }

    static func explain(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible: "This iPhone can't run Apple Intelligence."
        case .appleIntelligenceNotEnabled: "Apple Intelligence is off. Turn it on in Settings."
        case .modelNotReady: "Apple Intelligence is still downloading."
        @unknown default: "Apple Intelligence isn't available."
        }
    }

    /// The photo cropped to its most salient object, with a margin; the whole photo if
    /// Vision finds nothing that stands out.
    static func mainObject(in image: CGImage) async -> CGImage {
        guard let observation = try? await GenerateObjectnessBasedSaliencyImageRequest().perform(on: image),
              !observation.salientObjects.isEmpty else { return image }
        let size = CGSize(width: image.width, height: image.height)
        let union = observation.salientObjects
            .map { $0.boundingBox.toImageCoordinates(size, origin: .upperLeft) }
            .reduce(CGRect.null) { $0.union($1) }
        let crop = union.insetBy(dx: -union.width * 0.1, dy: -union.height * 0.1)
            .intersection(CGRect(origin: .zero, size: size))
            .integral
        // A tiny crop is more likely a detail than the thing itself.
        guard crop.width * crop.height > size.width * size.height * 0.05 else { return image }
        return image.cropping(to: crop) ?? image
    }

    static func see(_ image: CGImage) async -> VisionFindings {
        async let labels = (try? await ClassifyImageRequest().perform(on: image)) ?? []
        async let lines: [RecognizedTextObservation] = {
            // Accurate, not fast: brands are often small, embossed or low-contrast print.
            var request = RecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            return (try? await request.perform(on: image)) ?? []
        }()
        return VisionFindings(
            labels: await labels.filter { $0.confidence > 0.1 }.prefix(8).map(\.identifier),
            text: await lines.compactMap { $0.topCandidates(1).first?.string }.prefix(40).map { $0 }
        )
    }

    static func ask(_ model: SystemLanguageModel, image: CGImage, findings: VisionFindings, matches: [CatalogMatch] = []) async throws -> Suggestion {
        let session = LanguageModelSession(model: model, instructions: instructions)
        let details = Self.details(findings, matches: matches)
        let guess: ItemGuess
        let source: SuggestionSource
        if #available(iOS 27, macOS 27, *), model.capabilities.contains(.vision) {
            guess = try await session.respond(generating: ItemGuess.self) {
                Attachment(image).label("photo")
                details
            }.content
            source = .modelWithImage
        } else {
            guess = try await session.respond(to: details, generating: ItemGuess.self).content
            source = .modelWithLabels
        }
        log.info("Model (\(source.rawValue, privacy: .public)) named it: \(guess.name, privacy: .private)")
        return Suggestion(
            name: guess.name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: guess.category.trimmingCharacters(in: .whitespacesAndNewlines),
            aspects: SuggestedAspect.cleaned(guess.aspects.map { SuggestedAspect(name: $0.name, value: $0.value, choices: $0.choices) }),
            source: source
        )
    }

    static let instructions = """
        You help someone catalog the things they own at home, one photo at a time. \
        Name the single main object as specifically as you can be sure of, as they would \
        write it on a label: brand first when the text on it shows one, or when the product \
        is unmistakable from its design (an Apple laptop is an "Apple MacBook"); then the \
        product line or kind; then a key spec if shown. Not too broad: "Apple MacBook Air", \
        not "computer"; "Wooden dining chair", not "furniture". Not too narrow: never guess a \
        year, model number or size you can't see. Never invent a brand. \
        For example "RAVPower 61W USB-C charger", "Ray-Ban glasses case", "Bosch PSB 18 drill". \
        Then list its aspects, the ones that matter for owning, lending or selling this kind \
        of thing, most useful first: brand, model or generation, color, material, size, and \
        specs like chip, memory or storage. Fill in each value the photo or the text on it \
        shows, such as the brand or the color; leave it empty when the photo can't show it. \
        Give each two to five short, real choices, most likely first, so the owner picks in \
        one tap. \
        The labels come from a scene classifier and are often wrong about small objects: \
        trust the photo and the text on the object over them. Scene labels describe what's \
        around the object, such as the table it sits on; never name the object after them.
        """

    static func details(_ findings: VisionFindings, matches: [CatalogMatch] = []) -> String {
        let more = findings.text.count - findings.printedText.count
        let likely = matches.filter { $0.confidence != .low }
        return """
        \(likely.isEmpty ? "" : "A product catalog on this phone matched the photo to, best first: \(likely.map(\.name).joined(separator: ", ")). It's usually right about what kind of thing it is: name it after the first match unless the photo or the text on it clearly says otherwise, and fill in its aspects, including the brand in that name.")
        Labels that may name the object, most likely first: \(findings.objectLabels.isEmpty ? "none" : findings.objectLabels.joined(separator: ", ")).
        Scene and material labels, not the object: \(findings.sceneLabels.isEmpty ? "none" : findings.sceneLabels.joined(separator: ", ")).
        Short text printed on the object: \(findings.printedText.isEmpty ? "none" : findings.printedText.joined(separator: " | ")).
        \(more > 3 ? "There is also a lot of longer text, probably a screen or a page on the object: it's a device with a screen, a book or a document." : "")
        \(findings.brand.map { "The brand is probably \($0)." } ?? "")
        """
    }
}

@Generable
struct ItemGuess {
    @Guide(description: "Brand + product line or kind + key spec if visible, e.g. 'Apple MacBook Air', 'RAVPower 61W USB-C charger', 'Wooden dining chair'")
    var name: String
    @Guide(description: "One broad category: Tools, Garden, Sports, Bikes, Camping, Kitchen, Electronics, Furniture, Toys, Car, Household or Other")
    var category: String
    @Guide(description: "Its aspects, most useful first, e.g. Brand, Model, Color, Memory, Storage", .maximumCount(6))
    var aspects: [ItemAspect]
}

@Generable
struct ItemAspect {
    @Guide(description: "A short aspect name, e.g. 'Brand', 'Chip and year', 'Color', 'Memory', 'Storage', 'Material'")
    var name: String
    @Guide(description: "The value if the photo or the text on it shows it, e.g. 'Apple' or 'Silver'; empty if it can't be seen")
    var value: String
    @Guide(description: "Two to five short, real values, most likely first, e.g. '8 GB', '16 GB', '24 GB'", .count(2...5))
    var choices: [String]
}
