import CoreGraphics
import Foundation
import FoundationModels
import Vision

/// Suggests a name, category and resale guess from a photo, entirely on the phone (D5, X4):
/// Vision labels the photo and reads any text on it, then Apple's on-device Foundation
/// Models system model turns that, and the photo itself where the model can see images,
/// into an item. Only `SystemLanguageModel` is used, never Private Cloud Compute, so the
/// photo never leaves the device. Without Apple Intelligence, Vision's labels alone.
public struct OnDeviceSuggester: ItemSuggesting {
    public init() {}

    public func suggest(for image: CGImage, currency: String) async -> Suggestion {
        let findings = await Self.see(image)
        let model = SystemLanguageModel.default
        guard model.isAvailable else { return findings.fallbackSuggestion }
        do {
            return try await Self.ask(model, image: image, findings: findings, currency: currency)
        } catch {
            return findings.fallbackSuggestion
        }
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

    static func ask(_ model: SystemLanguageModel, image: CGImage, findings: VisionFindings, currency: String) async throws -> Suggestion {
        let session = LanguageModelSession(model: model, instructions: instructions)
        let details = Self.details(findings, currency: currency)
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
        let name = guess.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return findings.fallbackSuggestion }
        return Suggestion(
            name: name,
            category: guess.category.trimmingCharacters(in: .whitespacesAndNewlines),
            resaleEstimate: guess.resaleEstimate > 0 ? Decimal(guess.resaleEstimate) : nil,
            source: source
        )
    }

    static let instructions = """
        You help someone catalog the things they own at home, one photo at a time. \
        Name the single main object as they would write it on a label: short, with the brand \
        and model when the text on it shows them. Never invent a brand that isn't visible.
        """

    static func details(_ findings: VisionFindings, currency: String) -> String {
        """
        Labels from image recognition, most likely first: \(findings.labels.joined(separator: ", ")).
        Text read on the object: \(findings.text.isEmpty ? "none" : findings.text.joined(separator: " | ")).
        Give its resale estimate in \(currency), for a used one in fair condition.
        """
    }
}

@Generable
struct ItemGuess {
    @Guide(description: "Short everyday name with brand and model if visible, e.g. 'DeWalt 20V cordless drill' or 'Aluminium step ladder'")
    var name: String
    @Guide(description: "One broad category: Tools, Garden, Sports, Bikes, Camping, Kitchen, Electronics, Furniture, Toys, Car, Household or Other")
    var category: String
    @Guide(description: "Rough second-hand resale price as a whole number in the requested currency; 0 if unsure")
    var resaleEstimate: Int
}
