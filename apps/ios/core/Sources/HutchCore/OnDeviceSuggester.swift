import CoreGraphics
import Foundation
import FoundationModels
import OSLog
import Vision

/// Suggests a name and category from a photo, entirely on the phone (D5, X4):
/// 1. Vision finds the main object and crops to it, so a box on a shelf isn't read as "bookshelf".
/// 2. Vision labels the crop and reads any text on it.
/// 3. Apple's on-device Foundation Models system model turns that, and the crop itself where
///    the model can see images, into a name.
///
/// Only `SystemLanguageModel` is used, never Private Cloud Compute, so the photo never leaves
/// the device. Without Apple Intelligence, Vision's labels alone, with the reason why.
public struct OnDeviceSuggester: ItemSuggesting {
    /// The device's own log (Xcode's console, Console.app), never sent anywhere. Names and
    /// labels are marked private, so they're redacted outside a debugging session.
    static let log = Logger(subsystem: "app.myhutch.ios", category: "suggestions")

    public init() {}

    public func suggest(for image: CGImage) async -> Suggestion {
        let subject = await Self.mainObject(in: image)
        let findings = await Self.see(subject)
        Self.log.info("Vision labels: \(findings.labels.joined(separator: ", "), privacy: .private); text: \(findings.text.joined(separator: " | "), privacy: .private)")

        let model = SystemLanguageModel.default
        if case .unavailable(let reason) = model.availability {
            let why = Self.explain(reason)
            Self.log.notice("Apple Intelligence unavailable: \(why, privacy: .public)")
            return findings.fallbackSuggestion(because: why)
        }
        do {
            let suggestion = try await Self.ask(model, image: subject, findings: findings)
            if Suggestion.isPlaceholder(suggestion.name) {
                Self.log.notice("The model couldn't name it (\(suggestion.name, privacy: .private))")
                return findings.fallbackSuggestion(because: "Apple Intelligence couldn't tell what this is.")
            }
            return suggestion
        } catch {
            Self.log.error("The model failed: \(String(describing: error), privacy: .public)")
            return findings.fallbackSuggestion(because: "Apple Intelligence failed on this photo.")
        }
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
            var request = RecognizeTextRequest()
            request.recognitionLevel = .fast
            return (try? await request.perform(on: image)) ?? []
        }()
        return VisionFindings(
            labels: await labels.filter { $0.confidence > 0.1 }.prefix(8).map(\.identifier),
            text: await lines.compactMap { $0.topCandidates(1).first?.string }.prefix(6).map { $0 }
        )
    }

    static func ask(_ model: SystemLanguageModel, image: CGImage, findings: VisionFindings) async throws -> Suggestion {
        let session = LanguageModelSession(model: model, instructions: instructions)
        let details = Self.details(findings)
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
            source: source
        )
    }

    static let instructions = """
        You help someone catalog the things they own at home, one photo at a time. \
        Name the single main object as they would write it on a label: short, with the brand \
        and model when the text on it shows them. Never invent a brand that isn't visible. \
        The labels come from a scene classifier and are often wrong about small objects: \
        trust the photo and the text on the object over them.
        """

    static func details(_ findings: VisionFindings) -> String {
        """
        Labels from image recognition, most likely first: \(findings.labels.joined(separator: ", ")).
        Text read on the object: \(findings.text.isEmpty ? "none" : findings.text.joined(separator: " | ")).
        """
    }
}

@Generable
struct ItemGuess {
    @Guide(description: "Short everyday name with brand and model if visible, e.g. 'DeWalt 20V cordless drill' or 'Aluminium step ladder'")
    var name: String
    @Guide(description: "One broad category: Tools, Garden, Sports, Bikes, Camping, Kitchen, Electronics, Furniture, Toys, Car, Household or Other")
    var category: String
}
