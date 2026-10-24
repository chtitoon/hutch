import CoreGraphics
import Foundation
import Testing
@testable import HutchCore

@Suite struct ItemTests {
    /// Non-negotiable 2: new items are private.
    @Test func newItemsArePrivate() {
        #expect(Item(name: "Ladder").visibility == .private)
    }

    @Test func privateSurvivesAStoreRoundTrip() throws {
        let item = Item(name: "Ladder")
        let decoded = try JSONDecoder().decode(Item.self, from: JSONEncoder().encode(item))
        #expect(decoded.visibility == .private)
    }

    @Test func roomsUsedComeFirstThenHomeRoomsEachOnce() {
        let items = [
            Item(name: "a", room: "Garage", createdAt: .init(timeIntervalSince1970: 1)),
            Item(name: "b", room: " Attic ", createdAt: .init(timeIntervalSince1970: 3)),
            Item(name: "c", room: "garage", createdAt: .init(timeIntervalSince1970: 4)),
            Item(name: "d", room: "", createdAt: .init(timeIntervalSince1970: 5)),
        ]
        #expect(Item.rooms(used: items, home: ["Kitchen", "Attic", "Garage"]) == ["garage", "Attic", "Kitchen"])
        #expect(Item.rooms(used: [], home: []).isEmpty)
    }

    @Test func placeJoinsRoomAndSpot() {
        #expect(Item(name: "x", room: "Garage", spot: " left shelf").place == "Garage · left shelf")
        #expect(Item(name: "x", room: "Garage").place == "Garage")
        #expect(Item(name: "x").place.isEmpty)
    }
}

@Suite struct VaultTests {
    @Test func roundTrips() throws {
        let vault = Vault(key: Vault.newKey())
        let sealed = try vault.seal(Data("hello".utf8), context: "x")
        #expect(try vault.open(sealed, context: "x") == Data("hello".utf8))
    }

    @Test func sealsDifferentlyEachTime() throws {
        let vault = Vault(key: Vault.newKey())
        #expect(try vault.seal(Data("hello".utf8), context: "x") != vault.seal(Data("hello".utf8), context: "x"))
    }

    @Test func wrongContextFails() throws {
        let vault = Vault(key: Vault.newKey())
        let sealed = try vault.seal(Data("hello".utf8), context: "a.item")
        #expect(throws: (any Error).self) { try vault.open(sealed, context: "b.item") }
    }

    @Test func tamperingFails() throws {
        let vault = Vault(key: Vault.newKey())
        var sealed = try vault.seal(Data("hello".utf8), context: "x")
        sealed[sealed.count / 2] ^= 0x01
        #expect(throws: (any Error).self) { try vault.open(sealed, context: "x") }
    }
}

@Suite struct CaptureStatsTests {
    func item(_ seconds: Double, _ source: SuggestionSource, kept: Bool) -> Item {
        Item(name: "x", capture: CaptureRecord(
            seconds: seconds, suggestionSeconds: source == .none ? nil : 1.5, suggestionSource: source, keptSuggestedName: kept))
    }

    @Test func countsH1AndX4Signals() {
        let stats = CaptureStats(items: [
            item(12, .modelWithImage, kept: true),
            item(25, .labelsOnly, kept: false),
            item(8, .none, kept: false),
            Item(name: "typed in"),
        ])
        #expect(stats.itemCount == 4)
        #expect(stats.timedCount == 3)
        #expect(stats.medianSeconds == 12)
        #expect(stats.underTargetCount == 2)
        #expect(stats.suggestedCount == 2)
        #expect(stats.keptSuggestionCount == 1)
        #expect(stats.medianSuggestionSeconds == 1.5)
    }

    @Test func medianOfEvenCount() {
        #expect(CaptureStats.median([4, 1, 3, 2]) == 2.5)
        #expect(CaptureStats.median([]) == nil)
    }
}

@Suite struct SuggestionTests {
    @Test func fallbackSkipsGenericLabels() {
        let findings = VisionFindings(labels: ["tool", "power_drill", "machine"], text: ["DEWALT"])
        #expect(findings.fallbackSuggestion == Suggestion(name: "Power drill", source: .labelsOnly))
    }

    @Test func fallbackUsesAGenericLabelIfThatsAllThereIs() {
        #expect(VisionFindings(labels: ["furniture"], text: []).fallbackName == "Furniture")
    }

    @Test func noLabelsNoSuggestion() {
        #expect(VisionFindings(labels: [], text: []).fallbackSuggestion == .empty)
    }

    @Test func promptCarriesWhatVisionSaw() {
        let details = OnDeviceSuggester.details(VisionFindings(labels: ["ladder"], text: ["Werner"]))
        #expect(details.contains("ladder"))
        #expect(details.contains("Werner"))
    }
}

@Suite struct PhotoEncoderTests {
    @Test func downscalesToTheLongEdge() throws {
        let context = CGContext(data: nil, width: 400, height: 200, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        let jpeg = try PhotoEncoder.jpeg(context.makeImage()!, maxPixels: 100)
        let decoded = try #require(PhotoEncoder.image(from: jpeg))
        #expect(decoded.width == 100)
        #expect(decoded.height == 50)
    }
}
