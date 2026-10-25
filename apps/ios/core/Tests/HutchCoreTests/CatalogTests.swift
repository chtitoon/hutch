import Foundation
import Testing
@testable import HutchCore

@Suite struct CatalogTests {
    /// Three names in 2 dimensions, at 0°, 90° and 45°.
    let catalog = Catalog(
        names: ["laptop", "chair", "desk"],
        dimensions: 2,
        vectors: [1, 0, 0, 1, 0.7071, 0.7071],
        logitScale: 10,
        logitBias: -5
    )

    @Test func closestFirst() {
        let matches = catalog.matches(for: [1, 0])
        #expect(matches.map(\.name) == ["laptop", "desk", "chair"])
        #expect(matches[0].score > matches[1].score)
    }

    @Test func scoreIsSigLIPsSigmoid() {
        let best = catalog.matches(for: [1, 0], top: 1)[0]
        #expect(abs(best.score - Catalog.sigmoid(10 * 1 - 5)) < 1e-5)
    }

    @Test func wrongSizedEmbeddingMatchesNothing() {
        #expect(catalog.matches(for: [1, 0, 0]).isEmpty)
    }

    /// The files `tools/catalog-index/build.py` writes: JSON, and float16 vectors.
    @Test func readsBuildOutput() throws {
        let json = #"{"model":"m","built":"2026-10-24","dimensions":2,"logitScale":10,"logitBias":-5,"names":["a","b"]}"#
        let halves: [Float16] = [1, 0, 0, 1]
        let data = halves.withUnsafeBufferPointer { Data(buffer: $0) }
        let read = try Catalog(json: Data(json.utf8), vectors: data)
        #expect(read.names == ["a", "b"])
        #expect(read.matches(for: [0, 1], top: 1).first?.name == "b")
    }

    @Test func rejectsVectorsOfTheWrongSize() {
        let json = #"{"dimensions":2,"logitScale":1,"logitBias":0,"names":["a","b"]}"#
        #expect(throws: CatalogError.self) { try Catalog(json: Data(json.utf8), vectors: Data(count: 2)) }
    }

    @Test func confidenceFromTheScore() {
        #expect(CatalogMatch(name: "x", score: 0.93).confidence == .high)
        #expect(CatalogMatch(name: "x", score: 0.3).confidence == .high)
        #expect(CatalogMatch(name: "x", score: 0.1).confidence == .medium)
        #expect(CatalogMatch(name: "x", score: 0.01).confidence == .low)
    }
}

@Suite struct CombiningTests {
    let model = Suggestion(name: "Computer", category: "Electronics", aspects: [SuggestedAspect(name: "Color", value: "Black")], source: .modelWithImage)
    let vision = Suggestion(name: "Computer", source: .labelsOnly, fallbackReason: "Off.")

    @Test func aSureCatalogMatchNamesItAndKeepsTheModelsAspects() {
        let matches = [CatalogMatch(name: "Dell Inspiron Zino HD", score: 0.94), CatalogMatch(name: "Dell Inspiron desktop", score: 0.38)]
        let result = OnDeviceSuggester.combine(matches: matches, model: model, fallback: model)
        #expect(result.name == "Dell Inspiron Zino HD")
        #expect(result.source == .catalog)
        #expect(result.aspects == model.aspects)
        #expect(result.category == "Electronics")
        #expect(result.alternatives == ["Dell Inspiron desktop"])
        #expect(result.catalogScore == 0.94)
    }

    @Test func aLikelyMatchIsOfferedWhileTheModelNamesIt() {
        let matches = [CatalogMatch(name: "office chair", score: 0.11), CatalogMatch(name: "desk", score: 0.02)]
        let result = OnDeviceSuggester.combine(matches: matches, model: model, fallback: model)
        #expect(result.name == "Computer")
        #expect(result.source == .modelWithImage)
        #expect(result.alternatives == ["office chair"])
    }

    @Test func withoutAModelALikelyMatchIsOnlyOffered() {
        let matches = [CatalogMatch(name: "hand mixer", score: 0.12)]
        let result = OnDeviceSuggester.combine(matches: matches, model: nil, fallback: vision)
        #expect(result.name == "Computer")
        #expect(result.source == .labelsOnly)
        #expect(result.alternatives == ["hand mixer"])
        #expect(result.fallbackReason == "Off.")
    }

    @Test func unlikelyMatchesAreIgnored() {
        let result = OnDeviceSuggester.combine(matches: [CatalogMatch(name: "rake", score: 0.01)], model: nil, fallback: vision)
        #expect(result == vision)
    }

    @Test func noCatalogNoChange() {
        #expect(OnDeviceSuggester.combine(matches: [], model: model, fallback: model) == model)
    }

    @Test func theModelIsToldWhatTheCatalogMatched() {
        let details = OnDeviceSuggester.details(VisionFindings(labels: [], text: []), matches: [CatalogMatch(name: "hand mixer", score: 0.9), CatalogMatch(name: "rake", score: 0.01)])
        #expect(details.contains("is sure the photo shows: hand mixer."))
        #expect(!details.contains("rake"))
    }

    @Test func theModelIsWarnedWhenTheCatalogIsUnsure() {
        let details = OnDeviceSuggester.details(VisionFindings(labels: [], text: []), matches: [CatalogMatch(name: "hand mixer", score: 0.1), CatalogMatch(name: "whisk", score: 0.06)])
        #expect(details.contains("guessed, best first: hand mixer, whisk."))
        #expect(details.contains("often wrong"))
    }
}
